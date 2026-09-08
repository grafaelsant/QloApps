<div class="panel">
    <div class="panel-heading">
        <i class="icon-camera"></i> {l s='Inspeção Visual e Evidências Fotográficas de Governança' mod='qlovisualinspection'}
    </div>

    {if isset($inspectionError) && $inspectionError}
        <div class="alert alert-warning">
            <i class="icon-warning-sign"></i> {$inspectionError|escape:'html':'UTF-8'}
        </div>
    {/if}

    <form method="post" action="" enctype="multipart/form-data" class="form-horizontal">
        <div class="form-group">
            <label class="control-label col-lg-3 required">
                {l s='Quarto Inspecionado:' mod='qlovisualinspection'}
            </label>
            <div class="col-lg-5">
                <select name="room_id" class="form-control" required>
                    {foreach from=$roomsList item=room}
                        <option value="{$room.id|escape:'html':'UTF-8'}" {if isset($selectedRoomId) && $selectedRoomId == $room.id}selected="selected"{/if}>
                            {$room.name|escape:'html':'UTF-8'}
                        </option>
                    {/foreach}
                </select>
            </div>
        </div>

        <hr style="margin: 15px 0;" />

        <div class="form-group">
            <label class="control-label col-lg-3">
                <strong>{l s='Evidências por Item:' mod='qlovisualinspection'}</strong>
            </label>
            <div class="col-lg-8">
                <p class="text-muted" style="margin-bottom: 15px;">
                    {l s='Envie uma foto clara e nítida para cada um dos itens obrigatórios do quarto (JPEG/PNG, máx. 5 MB por foto).' mod='qlovisualinspection'}
                </p>

                <div class="row">
                    <!-- Item 1: Cama e Enxoval -->
                    <div class="col-md-4">
                        <div class="panel panel-default">
                            <div class="panel-heading" style="font-size: 0.95em; font-weight: bold;">
                                <i class="icon-bookmark"></i> 1. {l s='Cama e Enxoval' mod='qlovisualinspection'} <span class="text-danger">*</span>
                            </div>
                            <div class="panel-body">
                                <p class="small text-muted">{l s='Cama arrumada, lençóis esticados e travesseiros alinhados.' mod='qlovisualinspection'}</p>
                                <input type="file" name="photo_bed" accept="image/jpeg,image/png" class="form-control" required />
                            </div>
                        </div>
                    </div>

                    <!-- Item 2: Banheiro Higienizado -->
                    <div class="col-md-4">
                        <div class="panel panel-default">
                            <div class="panel-heading" style="font-size: 0.95em; font-weight: bold;">
                                <i class="icon-tint"></i> 2. {l s='Banheiro Higienizado' mod='qlovisualinspection'} <span class="text-danger">*</span>
                            </div>
                            <div class="panel-body">
                                <p class="small text-muted">{l s='Bancada limpa, espelho sem marcas e toalhas dobradas.' mod='qlovisualinspection'}</p>
                                <input type="file" name="photo_bath" accept="image/jpeg,image/png" class="form-control" required />
                            </div>
                        </div>
                    </div>

                    <!-- Item 3: Amenities Repostos -->
                    <div class="col-md-4">
                        <div class="panel panel-default">
                            <div class="panel-heading" style="font-size: 0.95em; font-weight: bold;">
                                <i class="icon-gift"></i> 3. {l s='Amenities Repostos' mod='qlovisualinspection'} <span class="text-danger">*</span>
                            </div>
                            <div class="panel-body">
                                <p class="small text-muted">{l s='Sabonetes, shampoos e itens de cortesia organizados.' mod='qlovisualinspection'}</p>
                                <input type="file" name="photo_amenities" accept="image/jpeg,image/png" class="form-control" required />
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <div class="form-group">
            <div class="col-lg-8 col-lg-offset-3">
                <button type="submit" name="submitInspection" class="btn btn-primary btn-lg">
                    <i class="icon-upload"></i> {l s='Avaliar e Salvar Evidências' mod='qlovisualinspection'}
                </button>
            </div>
        </div>
    </form>

    {if isset($itemsResults) && $itemsResults}
        <hr />
        
        <!-- Master Room Verdict Banner -->
        <div class="alert {if $overallAssessment == 'EVIDENCE_VALID'}alert-success{else}alert-danger{/if}" style="font-size: 1.15em;">
            <i class="{if $overallAssessment == 'EVIDENCE_VALID'}icon-check-circle{else}icon-exclamation-triangle{/if}"></i>
            <strong>{l s='Resultado Global da Inspeção:' mod='qlovisualinspection'}</strong>
            {if $overallAssessment == 'EVIDENCE_VALID'}
                <span class="label label-success" style="font-size: 0.9em; margin-left: 10px; padding: 4px 10px;">
                    {l s='TODAS AS EVIDÊNCIAS VÁLIDAS' mod='qlovisualinspection'}
                </span>
                <span style="margin-left: 10px;">{l s='O quarto atende aos critérios objetivos de qualidade e conformidade fotográfica.' mod='qlovisualinspection'}</span>
            {else}
                <span class="label label-danger" style="font-size: 0.9em; margin-left: 10px; padding: 4px 10px;">
                    {l s='REFAZER FOTOS COM NÃO CONFORMIDADE' mod='qlovisualinspection'}
                </span>
                <span style="margin-left: 10px;">{l s='Um ou mais itens não atingiram os limiares mínimos de nitidez ou luminosidade.' mod='qlovisualinspection'}</span>
            {/if}
        </div>

        <!-- Individual Item Audit Cards -->
        <div class="row">
            {foreach from=$itemsResults key=itemKey item=itemData}
                <div class="col-md-4">
                    <div class="panel {if isset($itemData.result.assessment) && $itemData.result.assessment == 'EVIDENCE_VALID'}panel-success{else}panel-danger{/if}">
                        <div class="panel-heading" style="font-weight: bold;">
                            <i class="{$itemData.icon|escape:'html':'UTF-8'}"></i> {$itemData.title|escape:'html':'UTF-8'}
                            <span class="pull-right">
                                {if isset($itemData.result.assessment) && $itemData.result.assessment == 'EVIDENCE_VALID'}
                                    <span class="badge badge-success">{l s='VÁLIDA' mod='qlovisualinspection'}</span>
                                {elseif isset($itemData.result.assessment)}
                                    <span class="badge badge-danger">{l s='RETAKE' mod='qlovisualinspection'}</span>
                                {else}
                                    <span class="badge badge-warning">{l s='SEM MÉTRICAS' mod='qlovisualinspection'}</span>
                                {/if}
                            </span>
                        </div>
                        <div class="panel-body text-center" style="background: #fafafa;">
                            {if isset($itemData.preview) && $itemData.preview}
                                <div style="margin-bottom: 10px;">
                                    <img src="{$itemData.preview}" alt="{$itemData.title|escape:'html':'UTF-8'}" style="max-width: 100%; height: auto; max-height: 180px; border-radius: 4px; border: 1px solid #ddd;" />
                                </div>
                            {/if}

                            {if isset($itemData.result) && $itemData.result}
                                <div class="row" style="margin-top: 10px;">
                                    <div class="col-xs-6" style="padding: 2px;">
                                        <div class="well well-sm" style="margin-bottom: 5px; background: #fff;">
                                            <div class="text-muted"><small>{l s='Brilho' mod='qlovisualinspection'}</small></div>
                                            <strong>{$itemData.result.metrics.luminance|string_format:"%.1f"}</strong>
                                            <div>
                                                {if $itemData.result.metrics.luminance_status == 'OPTIMAL'}
                                                    <span class="label label-success">{l s='Ideal' mod='qlovisualinspection'}</span>
                                                {elseif $itemData.result.metrics.luminance_status == 'UNDEREXPOSED'}
                                                    <span class="label label-danger">{l s='Escura' mod='qlovisualinspection'}</span>
                                                {else}
                                                    <span class="label label-warning">{l s='Estourada' mod='qlovisualinspection'}</span>
                                                {/if}
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-xs-6" style="padding: 2px;">
                                        <div class="well well-sm" style="margin-bottom: 5px; background: #fff;">
                                            <div class="text-muted"><small>{l s='Nitidez' mod='qlovisualinspection'}</small></div>
                                            <strong>{$itemData.result.metrics.sharpness_score|string_format:"%.1f"}</strong>
                                            <div>
                                                {if $itemData.result.metrics.sharpness_status == 'SHARP'}
                                                    <span class="label label-success">{l s='Nítida' mod='qlovisualinspection'}</span>
                                                {else}
                                                    <span class="label label-danger">{l s='Desfocada' mod='qlovisualinspection'}</span>
                                                {/if}
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div class="text-muted" style="margin-top: 4px;">
                                    <small>{$itemData.result.metrics.width|intval} &times; {$itemData.result.metrics.height|intval} px</small>
                                </div>

                                {if isset($itemData.result.warnings) && $itemData.result.warnings|@count > 0}
                                    <div class="text-left" style="margin-top: 8px; margin-bottom: 0; padding: 6px 10px; font-size: 0.82em; background-color: #fdf2f2; border: 1px solid #f8d7da; border-left: 3px solid #d9534f; border-radius: 3px; color: #a94442;">
                                        <div style="font-weight: bold; margin-bottom: 3px;">
                                            <i class="icon-warning-sign"></i> {l s='Ajustes necessários:' mod='qlovisualinspection'}
                                        </div>
                                        <ul style="padding-left: 15px; margin-bottom: 0;">
                                            {foreach from=$itemData.result.warnings item=warn}
                                                <li>
                                                    {if $warn == 'LOW_RESOLUTION'}
                                                        {l s='Resolução insuficiente (mín. 800x600).' mod='qlovisualinspection'}
                                                    {elseif $warn == 'UNDEREXPOSED'}
                                                        {l s='Foto muito escura. Acenda as luzes.' mod='qlovisualinspection'}
                                                    {elseif $warn == 'OVEREXPOSED'}
                                                        {l s='Foto com excesso de luz.' mod='qlovisualinspection'}
                                                    {elseif $warn == 'BLURRY_IMAGE'}
                                                        {l s='Foto desfocada ou tremida.' mod='qlovisualinspection'}
                                                    {else}
                                                        {$warn|escape:'html':'UTF-8'}
                                                    {/if}
                                                </li>
                                            {/foreach}
                                        </ul>
                                    </div>
                                {/if}
                            {elseif isset($itemData.error) && $itemData.error}
                                <div class="text-left" style="margin-top: 10px; margin-bottom: 0; padding: 6px 10px; font-size: 0.82em; background-color: #fcf8e3; border: 1px solid #faebcc; border-left: 3px solid #f0ad4e; border-radius: 3px; color: #8a6d3b;">
                                    <i class="icon-exclamation-triangle"></i> {$itemData.error|escape:'html':'UTF-8'}
                                </div>
                            {/if}
                        </div>
                    </div>
                </div>
            {/foreach}
        </div>
    {/if}
</div>

<!-- Fernando's View: Histórico de Auditoria de Inspeções -->
<div class="panel">
    <div class="panel-heading">
        <i class="icon-list-alt"></i> {l s='Histórico de Auditoria de Governança (Auditoria Gerencial)' mod='qlovisualinspection'}
        {if isset($recentInspections) && $recentInspections|@count > 0}
            <span class="badge">{$recentInspections|@count} {l s='registros' mod='qlovisualinspection'}</span>
        {/if}
    </div>

    {if isset($recentInspections) && $recentInspections|@count > 0}
        <div class="table-responsive">
            <table class="table table-bordered table-striped table-hover">
                <thead>
                    <tr class="nodrag nodrop">
                        <th class="text-center" style="width: 70px;">{l s='Evidência' mod='qlovisualinspection'}</th>
                        <th>{l s='Quarto' mod='qlovisualinspection'}</th>
                        <th>{l s='Item Inspecionado' mod='qlovisualinspection'}</th>
                        <th class="text-center">{l s='Veredito' mod='qlovisualinspection'}</th>
                        <th class="text-center">{l s='Luminância' mod='qlovisualinspection'}</th>
                        <th class="text-center">{l s='Nitidez' mod='qlovisualinspection'}</th>
                        <th class="text-center">{l s='Dimensões' mod='qlovisualinspection'}</th>
                        <th>{l s='Auditor / Inspetor' mod='qlovisualinspection'}</th>
                        <th class="text-center">{l s='Data e Hora' mod='qlovisualinspection'}</th>
                    </tr>
                </thead>
                <tbody>
                    {foreach from=$recentInspections item=row}
                        <tr>
                            <td class="text-center">
                                {if !empty($row.image_path)}
                                    <a href="{$moduleImgUri}{$row.image_path|escape:'html':'UTF-8'}" target="_blank" title="{l s='Ver imagem em tamanho original' mod='qlovisualinspection'}">
                                        <img src="{$moduleImgUri}{$row.image_path|escape:'html':'UTF-8'}" alt="Thumb" style="width: 45px; height: 35px; object-fit: cover; border-radius: 3px; border: 1px solid #ccc;" />
                                    </a>
                                {else}
                                    <span class="text-muted">—</span>
                                {/if}
                            </td>
                            <td>
                                <div>
                                    <strong>{$row.display_room_num|escape:'html':'UTF-8'}</strong>
                                    {if !empty($row.display_floor)}
                                        <span class="badge badge-default" style="font-size: 0.75em; font-weight: normal; margin-left: 4px;">
                                            {l s='Andar' mod='qlovisualinspection'} {$row.display_floor|escape:'html':'UTF-8'}
                                        </span>
                                    {/if}
                                </div>
                                {if !empty($row.display_room_type)}
                                    <div class="text-muted" style="max-width: 190px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; font-size: 0.85em; cursor: help;" title="{$row.full_room_title|escape:'html':'UTF-8'}">
                                        {$row.display_room_type|escape:'html':'UTF-8'}
                                    </div>
                                {/if}
                            </td>
                            <td>
                                {$row.item_title|escape:'html':'UTF-8'}
                            </td>
                            <td class="text-center">
                                {if $row.assessment == 'EVIDENCE_VALID'}
                                    <span class="badge badge-success">{l s='VÁLIDA' mod='qlovisualinspection'}</span>
                                {else}
                                    <span class="badge badge-danger">{l s='RETAKE' mod='qlovisualinspection'}</span>
                                {/if}
                            </td>
                            <td class="text-center">
                                <strong>{$row.luminance|string_format:"%.1f"}</strong>
                                <small class="text-muted">({$row.luminance_status|escape:'html':'UTF-8'})</small>
                            </td>
                            <td class="text-center">
                                <strong>{$row.sharpness_score|string_format:"%.1f"}</strong>
                                <small class="text-muted">({$row.sharpness_status|escape:'html':'UTF-8'})</small>
                            </td>
                            <td class="text-center">
                                {$row.width|intval} &times; {$row.height|intval} px
                            </td>
                            <td>
                                {if !empty($row.employee_name)}
                                    {$row.employee_name|escape:'html':'UTF-8'}
                                {else}
                                    <span class="text-muted">{l s='Supervisor' mod='qlovisualinspection'}</span>
                                {/if}
                            </td>
                            <td class="text-center">
                                {$row.date_add|date_format:"%d/%m/%Y %H:%M"}
                            </td>
                        </tr>
                    {/foreach}
                </tbody>
            </table>
        </div>
    {else}
        <div class="alert alert-info" style="margin: 15px;">
            <i class="icon-info-circle"></i> {l s='Nenhum registro de inspeção salvo até o momento. As avaliações salvas no formulário acima serão arquivadas nesta tabela para consulta e auditoria.' mod='qlovisualinspection'}
        </div>
    {/if}
</div>
