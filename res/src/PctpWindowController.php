<?php

require_once __DIR__.'/../inc/restriction.php';

class PctpWindowController extends ASerializableClass
{
    public PctpWindowModel $model;

    public function __construct()
    {
        $this->model = new PctpWindowModel();
    }

    public function initialize(): IAction 
    {
        unset($_SESSION['appendedData']);
        $this->model->reinitializeModel();
        $hybridHeader = (array)$this->model->header;
        $hybridHeader['method'] = 'initialize';
        $hybridHeader['viewOptions'] = $this->model->viewOptions;
        $hybridHeader['config'] = $this->model->getSettings()->config;
        $hybridHeader['sapDocumentStructures'] = $this->model->getSettings()->sapDocumentStructures;
        $hybridHeader['uploadedAttachment'] = [
            'pod' => $this->model->podTab->getAttachmentObjs($this->model->header),
            'billing' => $this->model->billingTab->getAttachmentObjs($this->model->header),
            'tp' => $this->model->tpTab->getAttachmentObjs($this->model->header),
        ];
        $hybridHeader['fieldEnumValues'] = [
            'pod' => $this->model->podTab->fieldEnumValues,
            'billing' => $this->model->billingTab->fieldEnumValues,
            'tp' => $this->model->tpTab->fieldEnumValues,
            'pricing' => $this->model->pricingTab->fieldEnumValues,
        ];
        $hybridHeader['foreignFields'] = [
            'pod' => $this->model->podTab->foreignFields,
            'billing' => $this->model->billingTab->foreignFields,
            'tp' => $this->model->tpTab->foreignFields,
            'pricing' => $this->model->pricingTab->foreignFields,
        ];
        $hybridHeader['actionValidations'] = $this->model->actionValidations;
        $hybridHeader['columnValidations'] = $this->model->getColumnValidations();
        $hybridHeader['columnDefinitions'] = $this->model->getColumnDefinitions();
        $hybridHeader['dropDownOptions'] = $this->model->getSettings()->dropDownOptions;
        $hybridHeader['constants'] = $this->model->getSettings()->constants;
        $hybridHeader['userInfo'] = [
            'sessionId' => session_id(),
            'userName' => $_SESSION['SESS_NAME'],
            'userId' => $_SESSION['SESS_USERID'],
        ];
        $this->model->isInitialized = true;
        return new class((object)['hybridHeader' => $hybridHeader]) implements IAction {
            function __construct(private object $obj){}
            function echo(): string
            {
                return json_encode($this->obj->hybridHeader);
            }
        };
        // $this->model->processHybridHeader();
        // $this->model->isInitialized = true;
        // return new class((object)['hybridHeader' => $this->model->hybridHeader]) implements IAction {
        //     function __construct(private object $obj){}
        //     function echo(): string
        //     {
        //         return json_encode($this->obj->hybridHeader);
        //     }
        // };
    }

    public function find(object $data): IAction 
    {
        $modelTab = $this->model->{$data->activeTab.'Tab'};
        $modelTab->storeHeaderData($this->model, $data->header);
        $modelTab->countFetchTableRows(
            $this->model->settings->viewOptions['data_table_common_find_header'] ?
            $this->model->findHeader : $modelTab->findHeader
        );
        $uploadedAttachment = $modelTab->getAttachmentObjs(
            $this->model->settings->viewOptions['data_table_common_find_header'] ?
            $this->model->findHeader : $modelTab->findHeader
        );
        $data->fetchTableRowsCount = $modelTab->fetchTableRowsCount;
        return new class((object)['uploadedAttachment' => $uploadedAttachment, 'data' => $data]) implements IAction {
            function __construct(private object $obj){}
            function echo(): string
            {
                return json_encode([
                    'result' => 'success',
                    'resultData' => $this->obj->data,
                    'callback' => 'reloadTab',
                    'arg' => [
                        'tab' => $this->obj->data->activeTab,
                        'uploadedAttachment' => $this->obj->uploadedAttachment,
                    ]
                ]);
            }
        };
    }

    public function update(object $data): IAction 
    {
        $tab = $this->model->{$data->activeTab.'Tab'};
        $result = $tab->updateRows($this->model, $data->rows);
        $relatedDataRows = [];
        if ((bool)$tab->relatedTables && $result) {
            $relatedDataRows = $this->model->searchRelatedDataRows($tab, $data->rows);
        }
        $this->model->currentMethod = 'update';
        return new class((object)['model' => $this->model, 'data' => $data, 'result' => $result, 'relatedDataRows' => $relatedDataRows]) implements IAction {
            function __construct(private object $obj){}
            function echo(): string
            {
                return json_encode([
                    'result' => $this->obj->result ? 'success' : 'failed',
                    'message' => $this->obj->result ? 'Selected rows updated successfully' : 'Update failed',
                    'callback' => 'refreshUpdatedRows',
                    'arg' => [
                        'tab' => $this->obj->data->activeTab,
                        'rows' => $this->obj->data->rows,
                        'rDataRows' => $this->obj->relatedDataRows
                    ]
                ]);
            }
        };
    }

    public function groupFieldUpdate(object $data): IAction 
    {
        $tab = $this->model->{$data->activeTab.'Tab'};
        $result = $tab->groupFieldUpdate(
            $this->model->settings->viewOptions['data_table_common_find_header'] ?
            $this->model->findHeader : $tab->findHeader,
            $data->groupFieldProps,
            !isset($data->excludedRowsFromSelection) || !(bool)$data->excludedRowsFromSelection ? null : array_map(fn($z) => preg_replace('/\D+/', '', $z), $data->excludedRowsFromSelection),
        );
        $this->model->currentMethod = 'groupFieldUpdate';
        return new class((object)['model' => $this->model, 'data' => $data, 'result' => $result]) implements IAction {
            function __construct(private object $obj){}
            function echo(): string
            {
                return json_encode([
                    'result' => $this->obj->result ? 'success' : 'failed',
                    'message' => $this->obj->result ? 'Selected rows updated successfully' : 'Update failed',
                    'callback' => '',
                ]);
            }
        };
    }

    public function addManualPod(): IAction 
    {
        $this->model->currentMethod = 'addManualPod';
        return new class($this) implements IAction {
            function __construct(private object $obj){}
            function echo(): string
            {
                return 'addManualPod';
            }
        };
    }

    public function createSalesOrder(object $data): IAction 
    {
        $tab = $this->model->{$data->activeTab.'Tab'};
        $result = $tab->postTransaction($this->model, $data->sapObj, $this->model->getSettings()->sapDocumentStructures->SALES_ORDER);
        if (!$result->valid) {
            if (str_contains($result->message, 'Cannot concentrate summary cards  [ORDR.FatherCard]')) {
                $messageArr = explode(',', $result->message);
                $cardCode = $messageArr[1];
                $result->message = "The consolidating BP of card code $cardCode has open AR transactions. You need to close them first in order to post SO for $cardCode.
                You can identify the consolidating BP by going to SAP > BP Master Data > Record for $cardCode > Accounting tab > Consolidating BP.";
            }
        }
        return new class((object)['data' => $data, 'result' => $result]) implements IAction {
            function __construct(private object $obj){}
            function echo(): string
            {
                return json_encode([
                    'result' => $this->obj->result->valid ? 'success' : 'failed',
                    'resultData' => $this->obj->result,
                    'callback' => '',
                    'arg' => [
                        'tab' => $this->obj->data->activeTab,
                    ]
                ]);
            }
        };
    }

    public function createArInvoice(object $data): IAction 
    {
        $tab = $this->model->{$data->activeTab.'Tab'};
        $result = $tab->postTransaction($this->model, $data->sapObj, $this->model->getSettings()->sapDocumentStructures->AR_INVOICE);
        return new class((object)['data' => $data, 'result' => $result]) implements IAction {
            function __construct(private object $obj){}
            function echo(): string
            {
                $rowCodes = [];
                foreach ($this->obj->data->sapObj->lines as $line) {
                    $rowCodes[] = $line->rowData->rowCode;
                }
                return json_encode([
                    'result' => $this->obj->result->valid ? 'success' : 'failed',
                    'resultData' => $this->obj->result,
                    'callback' => 'refreshDataRow',
                    'arg' => [
                        'tab' => $this->obj->data->activeTab,
                        'tabName' => $this->obj->data->activeTab,
                        'rowCodes' => $rowCodes,
                    ]
                ]);
            }
        };
    }

    public function createApInvoice(object $data): IAction 
    {
        $tab = $this->model->{$data->activeTab.'Tab'};
        $result = $tab->postTransaction($this->model, $data->sapObj, $this->model->getSettings()->sapDocumentStructures->AP_INVOICE);
        return new class((object)['data' => $data, 'result' => $result]) implements IAction {
            function __construct(private object $obj){}
            function echo(): string
            {
                $rowCodes = [];
                foreach ($this->obj->data->sapObj->lines as $line) {
                    $rowCodes[] = $line->rowData->rowCode;
                }
                return json_encode([
                    'result' => $this->obj->result->valid ? 'success' : 'failed',
                    'resultData' => $this->obj->result,
                    'callback' => 'refreshDataRow',
                    'arg' => [
                        'tab' => $this->obj->data->activeTab,
                        'tabName' => $this->obj->data->activeTab,
                        'rowCodes' => $rowCodes,
                    ]
                ]);
            }
        };
    }

    private function log(string $methodName, object $data): void 
    {
        $logMessage = date(DATE_COOKIE);
        $logMessage .= ' ~ '.$_SERVER['HTTP_REFERER'];
        $logMessage .= ' ~ SESSION:'.session_id();
        $logMessage .= ' ~ METHOD:'.$methodName;
        $logMessage .= ' ~ ARG:'.json_encode($data);
        $logMessage .= "\n";
        file_put_contents(__DIR__.'/../logs/controller.txt', $logMessage, FILE_APPEND | LOCK_EX);
    }

    public function refreshExtractTables(object $data): IAction 
    {
        try {
            $this->log('refreshExtractTables[START]', $data);
            if (isset($data->bookingIds) && (bool)$data->bookingIds && is_array($data->bookingIds)) {
                $bookingIds = array_map(fn($z) => (object)['BookingId' => $z], $data->bookingIds);
                $this->model->summaryTab->preFetchProcess($bookingIds, $this->model->getSettings()->preFetchRefreshScripts);
            }
            $return = [
                'result' => 'success',
                'data' => ['result' => 'success'],
            ];
        } catch (\Throwable $th) {
            $return = [
                'result' => 'failed',
                'data' => ['message' => $th->getMessage()],
            ];
        }
        $this->log('refreshExtractTables[END]', json_decode(json_encode($return)));
        return new class((object)['data' => $return]) implements IAction
        {
            function __construct(private object $obj) { }
            function echo(): string {
                return json_encode($this->obj->data);
            }
        };
    }

    public function fetchTest(object $data): IAction
    {
        try {
            $return = [
                'result' => 'success',
                'data' => ['message' => $data->message],
            ];
        } catch (\Throwable $th) {
            $return = [
                'result' => 'failed',
                'data' => ['message' => $th->getMessage()],
            ];
        }
        return new class((object)['data' => $return]) implements IAction
        {
            function __construct(private object $obj) { }
            function echo(): string {
                return json_encode($this->obj->data);
            }
        };
    }
}