<?php
/**
 * Admin Controller for Visual Inspection and Housekeeping Quality Evaluation
 *
 * @author    QloApps Engineering
 * @copyright Since 2026 QloApps
 * @license   https://opensource.org/licenses/AFL-3.0 Academic Free License 3.0 (AFL-3.0)
 */

if (!defined('_PS_VERSION_')) {
    exit;
}

class AdminVisualInspectionController extends ModuleAdminController
{
    const PYTHON_SERVICE_URL = 'http://127.0.0.1:8102/v1/visual-inspections';
    const CURL_TIMEOUT_MS = 800;
    const MAX_FILE_SIZE_BYTES = 5242880; // 5 MB

    public function __construct()
    {
        $this->bootstrap = true;
        $this->override_folder = '';
        parent::__construct();
    }

    const INSPECTION_ITEMS = [
        'bed' => [
            'field' => 'photo_bed',
            'title' => '1. Cama e Enxoval',
            'icon'  => 'icon-bookmark',
        ],
        'bath' => [
            'field' => 'photo_bath',
            'title' => '2. Banheiro Higienizado',
            'icon'  => 'icon-tint',
        ],
        'amenities' => [
            'field' => 'photo_amenities',
            'title' => '3. Amenities Repostos',
            'icon'  => 'icon-gift',
        ],
    ];

    /**
     * Main action to render and process the room inspection form
     */
    public function initContent()
    {
        parent::initContent();

        $itemsResults = [];
        $errorMessage = null;
        $selectedRoomId = null;
        $overallAssessment = 'EVIDENCE_VALID';

        if (Tools::isSubmit('submitInspection')) {
            $selectedRoomId = Tools::getValue('room_id');
            $allowedMimes = ['image/jpeg', 'image/png', 'image/pjpeg', 'image/x-png'];
            $hasAnyError = false;

            foreach (self::INSPECTION_ITEMS as $itemKey => $itemConfig) {
                $fieldName = $itemConfig['field'];
                $itemResult = null;
                $itemError = null;
                $previewBase64 = null;

                if (!isset($_FILES[$fieldName]) || $_FILES[$fieldName]['error'] !== UPLOAD_ERR_OK) {
                    $itemError = $this->l('Foto não enviada para este item.');
                    $hasAnyError = true;
                    $overallAssessment = 'EVIDENCE_REQUIRES_RETAKE';
                } else {
                    $tmpFilePath = $_FILES[$fieldName]['tmp_name'];
                    $fileSize = (int) $_FILES[$fieldName]['size'];

                    if ($fileSize > self::MAX_FILE_SIZE_BYTES) {
                        $itemError = $this->l('Foto excede o limite máximo permitido de 5 MB.');
                        $hasAnyError = true;
                        $overallAssessment = 'EVIDENCE_REQUIRES_RETAKE';
                    } else {
                        $mimeType = function_exists('mime_content_type') ? mime_content_type($tmpFilePath) : $_FILES[$fieldName]['type'];

                        if (!in_array($mimeType, $allowedMimes)) {
                            $itemError = $this->l('Formato inválido. Apenas JPEG ou PNG.');
                            $hasAnyError = true;
                            $overallAssessment = 'EVIDENCE_REQUIRES_RETAKE';
                        } else {
                            $fileData = @file_get_contents($tmpFilePath);
                            if ($fileData) {
                                $previewBase64 = 'data:' . $mimeType . ';base64,' . base64_encode($fileData);
                            }

                            $subInspectionId = 'INSP-' . date('YmdHis') . '-' . preg_replace('/[^a-zA-Z0-9_-]/', '', (string)$selectedRoomId) . '-' . $itemKey;
                            $correlationId = Tools::passwdGen(16, 'ALPHANUMERIC');

                            $cFile = new CURLFile($tmpFilePath, $mimeType, $_FILES[$fieldName]['name']);
                            $postData = [
                                'file'          => $cFile,
                                'room_id'       => (string) $selectedRoomId,
                                'inspection_id' => $subInspectionId,
                            ];

                            $ch = curl_init(self::PYTHON_SERVICE_URL);
                            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
                            curl_setopt($ch, CURLOPT_POST, true);
                            curl_setopt($ch, CURLOPT_POSTFIELDS, $postData);
                            curl_setopt($ch, CURLOPT_TIMEOUT_MS, self::CURL_TIMEOUT_MS);
                            curl_setopt($ch, CURLOPT_HTTPHEADER, [
                                'X-Correlation-ID: ' . $correlationId,
                            ]);

                            $response = curl_exec($ch);
                            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
                            curl_close($ch);

                            if ($response && $httpCode === 200) {
                                $itemResult = json_decode($response, true);
                                if (isset($itemResult['assessment']) && $itemResult['assessment'] !== 'EVIDENCE_VALID') {
                                    $overallAssessment = 'EVIDENCE_REQUIRES_RETAKE';
                                }
                            } elseif ($httpCode === 400) {
                                $errJson = json_decode($response, true);
                                $itemError = !empty($errJson['detail']) ? $errJson['detail'] : $this->l('Imagem rejeitada pelo validador.');
                                $hasAnyError = true;
                                $overallAssessment = 'EVIDENCE_REQUIRES_RETAKE';
                            } else {
                                $itemError = $this->l('Métricas indisponíveis (Serviço local offline).');
                            }
                        }
                    }
                }

                $itemsResults[$itemKey] = [
                    'title'   => $itemConfig['title'],
                    'icon'    => $itemConfig['icon'],
                    'preview' => $previewBase64,
                    'result'  => $itemResult,
                    'error'   => $itemError,
                ];
            }

            if ($hasAnyError) {
                $errorMessage = $this->l('Uma ou mais evidências fotográficas apresentaram problemas ou necessitam de retake.');
            }
        }

        $this->context->smarty->assign([
            'itemsResults'      => $itemsResults,
            'overallAssessment' => $overallAssessment,
            'inspectionError'   => $errorMessage,
            'selectedRoomId'    => $selectedRoomId,
            'roomsList'         => $this->getHotelRoomsList(),
        ]);

        $this->template = 'content.tpl';
        $this->content .= $this->context->smarty->fetch($this->getTemplatePath() . 'inspection_form.tpl');
        $this->context->smarty->assign('content', $this->content);
    }

    /**
     * Retrieve active hotel rooms from database or fallback list
     *
     * @return array
     */
    protected function getHotelRoomsList()
    {
        $rooms = [];

        try {
            if (class_exists('Db')) {
                $sql = 'SELECT r.`id` AS id_room, r.`room_num`, r.`id_status`, r.`floor`
                        FROM `' . _DB_PREFIX_ . 'htl_room_information` r
                        ORDER BY r.`room_num` ASC LIMIT 50';
                $dbRooms = Db::getInstance()->executeS($sql);

                if (!empty($dbRooms)) {
                    foreach ($dbRooms as $row) {
                        $rooms[] = [
                            'id'   => 'room-' . (int) $row['id_room'],
                            'name' => 'Quarto ' . $row['room_num'] . (!empty($row['floor']) ? ' (Andar ' . $row['floor'] . ')' : ''),
                        ];
                    }
                }
            }
        } catch (Exception $e) {
            PrestaShopLogger::addLog($e->getMessage(), 3);
        }

        if (empty($rooms)) {
            $rooms = [
                ['id' => 'room-101', 'name' => 'Quarto 101 (Standard)'],
                ['id' => 'room-102', 'name' => 'Quarto 102 (Deluxe)'],
                ['id' => 'room-201', 'name' => 'Quarto 201 (Suíte Presidencial)'],
                ['id' => 'room-202', 'name' => 'Quarto 202 (Executivo)'],
            ];
        }

        return $rooms;
    }
}
