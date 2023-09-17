<?php

require_once __DIR__.'/../inc/restriction.php';

final class PctpAPI
{
    private static PctpAPI $instance;
    private function __construct(){}
    private static PctpWindowSettings $settings;
    public static function getInstance(PctpWindowSettings $settings) {
        if (isset(self::$instance) && self::$instance !== null) {
            return self::$instance;
        }
        self::$instance = new PctpAPI();
        self::$settings = $settings;
        return self::$instance;
    }

    public function getTableRowsDataWithHeaders(PctpWindowModel &$model, object $data) {
        try {
            $tabKeyword = $data->tab;
            $modelTab = $model->{$tabKeyword.'Tab'};
            $modelTab->methodTrack = 'getTableRowsDataWithHeaders';
            $tableRows = [];
            $tableRows[] = array_map(fn($z) => $z->description, $modelTab->columnDefinitions);
            $rowDataArrays = $modelTab->getTableRowsData(true, isset($data->dataTableSetting) ? $data->dataTableSetting : null, true, isset($data->fetchedIdsToProcess) ? $data->fetchedIdsToProcess : null);
            $modelTab->methodTrack = '';
            foreach ($rowDataArrays as $rowDataArray) {
                $tableRows[] = $rowDataArray;
            }
            $return = [
                'result' => 'success',
                'data' => $tableRows,
            ];
        } catch (\Exception $e) {
            $return = [
                'result' => 'failed',
                'message' => strval($e)
            ];
        }
        return new class((object)['data' => $return]) implements IAction {
            function __construct(private object $obj){}
            function echo(): string
            {
                return json_encode($this->obj->data);
            }
        };
    }

    public function fetchDataRows(PctpWindowModel &$model, object $data): IAction
    {
        $dataRows = [];
        $tabKeyword = $data->tab;
        $modelTab = $model->{$tabKeyword.'Tab'};
        $columnDefinitions = $modelTab->columnDefinitions;
        $modelTab->fetchRows(
            self::$settings->viewOptions['data_table_common_find_header'] ?
            $model->findHeader : $modelTab->findHeader, 
            $data->dataTableSetting,
            true,
            true,
            isset($data->fetchedIdsToProcess) ? $data->fetchedIdsToProcess : null
        );
        $tableRows = $modelTab->tableRows;
        if ((bool)$tableRows) {
            $tableRowIndex = $data->dataTableSetting->start;
            foreach ($tableRows as $tableRow) {
                $dataRows[] = $this->createDataRow($model, $tabKeyword, $tableRow, ++$tableRowIndex);
            }
        }
        return new class((object)['dataRows' => $dataRows]) implements IAction {
            function __construct(private object $obj){}
            function echo(): string
            {
                return json_encode(['data' => $this->obj->dataRows]);
            }
        };
    }

    public function fetchDataRow(PctpWindowModel &$model, object $data): IAction
    {
        $tabKeyword = $data->tab;
        $return = '';
        $realCode = str_replace($tabKeyword, '', $data->code);
        if ($tableRow = $model->{$tabKeyword.'Tab'}->getRowReferenceByKey($realCode, true)) {
            PctpWindowTabHelper::getInstance(self::$settings)->formatRowFieldValues($model->{$tabKeyword.'Tab'}, $tableRow);
            $dataRow = $this->createDataRow($model, $tabKeyword, $tableRow, $data->tableRowIndex);
            $return = !(bool)$dataRow ? '' : [
                'result' => 'success',
                'data' => $dataRow,
            ];
        } else {
            $return = [
                'result' => 'failed',
                'message' => 'no row reference found'
            ];
        }
        return new class((object)['data' => $return]) implements IAction {
            function __construct(private object $obj){}
            function echo(): string
            {
                if ((bool)$this->obj->data) {
                    return json_encode($this->obj->data);
                }
                return '';
            }
        };
    }

    private function createDataRow(PctpWindowModel $model, string $tabKeyword, object $tableRow,  int $tableRowIndex): array
    {
        $columnDefinitions = $model->{$tabKeyword.'Tab'}->columnDefinitions;
        $dataRow = [];
        $dataRow[] = '<span data-pctp-row="'.$tableRowIndex.'" class="rowNo" data-pctp-code="'.(isset($tableRow->Code) ? $tabKeyword.$tableRow->Code : '').'">'.$tableRowIndex.'</span>';
        if ($tabKeyword !== 'summary') {
            $checkbox = '
                <input type="checkbox" onclick="selectTableRow($(this));selectRow($(this));" class="checkselrow checkrow'.$tabKeyword.'" 
                    style="vertical-align: middle; width: 20px; height: 20px;"
                    title="'.($tabKeyword === 'pod' ? 'This will only be checked/selected if changes have been made in this row.' : '').'">
            ';
            $dataRow[] = preg_replace('/\s+/', ' ', trim($checkbox));
        }
        foreach ($columnDefinitions as $columnDefinition) {
            if ($columnDefinition->columnViewType === ColumnViewType::HIDDEN) continue;
            ob_start();
            include(__DIR__.'/../../templates/components/data-row.php');
            $dataRow[] = preg_replace('/\s+/', ' ', trim(ob_get_contents()));
            ob_end_clean();
        }
        return $dataRow;
    }

    public function getData(PctpWindowModel &$model, object $data): IAction
    {
        $return = '';
        try {
            if (isset($data->doRefresh) && $data->doRefresh) {
                self::$settings->reFreshData($model, $data->prop);
            }
            if (isset($data->data) && isset($data->field) && isset($data->value)) {
                $result = array_values(array_filter(self::$settings->{$data->prop}[$data->data], fn($z) => $z->{$data->field} === $data->value));
                $return = !(bool)$result ? '' : [
                    'result' => 'success',
                    'data' => $result[0],
                ];
            } else {
                $return = [
                    'result' => 'success',
                    'data' => self::$settings->{$data->prop},
                ];
            }
        } catch (\Exception $e) {
            $return = [
                'result' => 'failed',
                'message' => strval($e)
            ];
        }
        return new class((object)['data' => $return]) implements IAction {
            function __construct(private object $obj){}
            function echo(): string
            {
                if ((bool)$this->obj->data && isset($this->obj->data['data'])) {
                    foreach ((array)$this->obj->data['data'] as $key => $value) {
                        if (is_string($value) && strlen($value) != strlen(utf8_decode($value))) {
                            if (is_array($this->obj->data['data'])) {
                                $this->obj->data['data'][$key] = utf8_decode($value);
                            } else {
                                $this->obj->data['data']->{$key} = utf8_decode($value);
                            }
                            
                        }
                    }
                    return json_encode($this->obj->data);
                }
                return '';
            }
        };
    }

    public function validateData(PctpWindowModel &$model, object $data): IAction
    {
        $result = $model->{$data->tab.'Tab'}->{$data->validation}($data->arg);
        $return = [
            'result' => 'success',
            'data' => ['result' => $result],
        ];
        return new class((object)['data' => $return]) implements IAction {
            function __construct(private object $obj){}
            function echo(): string
            {
                if ((bool)$this->obj->data) {
                    return json_encode($this->obj->data);
                }
                return '';
            }
        };
    }
}
