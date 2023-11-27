<?php 
    require_once __DIR__.'/../../res/inc/autoload.php';
    $model = PctpWindowFactory::getObject('PctpWindowController')->model;
    $tabKeyword = $_GET['tab'];
    $columnDefinitions = $model->{$tabKeyword.'Tab'}->columnDefinitions;
    $tableRows = $model->{$tabKeyword.'Tab'}->tableRows;
    $fetchTableRowsCount = $model->{$tabKeyword.'Tab'}->fetchTableRowsCount;
?>

<table id="tabtbl<?= $tabKeyword ?>" class="table text-center table-striped table-bordered table-sm detailsTable pctpTabTable" style="border-collapse: separate; background-color: lightgray; width: 100%; " name="mainTable1">
    <thead style="position: sticky; top: 0px; border-bottom: 0 !important;">
        <tr>
            <th style="position: sticky; top: 0px; color: black; vertical-align: middle; background-color: white !important;">#</th>
            <?php if($tabKeyword !== 'summary'): ?>
                <th style="position: sticky; top: 0px; color: black; vertical-align: middle; background-color: white !important;">
                    <?php if((bool)$fetchTableRowsCount && in_array($tabKeyword, ['pod', 'billing', 'tp'])): ?>
                        <input id="chkall<?= $tabKeyword ?>" type="checkbox" onclick="selectUnselectAll($(this),'<?= $tabKeyword ?>')" style="vertical-align: middle; width: 20px; height: 20px;">
                    <?php endif ?>
                </th>
            <?php endif ?>
            <?php foreach($columnDefinitions as $columnDefinition): ?>
                <?php if ($columnDefinition->columnViewType === ColumnViewType::HIDDEN) : ?>
                    <?php continue; ?>
                <?php else : ?>
                <th style="position: sticky; top: 0px; color: black; vertical-align: middle; background-color: white !important;"><span><?= $columnDefinition->description ?></span></th>
                <?php endif ?>
            <?php endforeach ?>
        </tr>
    </thead>
    <tbody>
        <?php if(!(bool)$fetchTableRowsCount): ?>
            <tr>
                <td class="nodataplaceholder" style="text-align: left; vertical-align: middle; background-color: lightgray;" colspan="<?= count($columnDefinitions) + 2 ?>">NO DATA FOUND</td>
            </tr>
        <?php endif ?>
    </tbody>
    <tfoot>
        <tr>
            <th style="background-color: lightgray !important; border-color: lightgray !important;"></th>
            <?php if($tabKeyword !== 'summary'): ?>
                <th style="background-color: lightgray !important; border-color: lightgray !important;"></th>
            <?php endif ?>
            <?php foreach($columnDefinitions as $columnDefinition): ?>
                <?php if ($columnDefinition->columnViewType === ColumnViewType::HIDDEN) : ?>
                    <?php continue; ?>
                <?php else : ?>
                    <th style="background-color: lightgray !important; border-color: lightgray !important;"></th>
                <?php endif ?>
            <?php endforeach ?>
        </tr>
    </tfoot>
</table>

<style>
    .pctpTabTable td {
        vertical-align: middle;
        background-color: <?= $model->viewOptions['td_background_color'] ?>;
    }
</style>