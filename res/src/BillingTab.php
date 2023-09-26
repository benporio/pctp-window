<?php
// -- WaybillNo
// -- Waybill #

// -- ShipmentManifestNo
// -- Shipment No / Manifest No

// -- DeliveryReceiptNo
// -- Delivery Receipt No

// -- SeriesNo
// -- Series #
require_once __DIR__ . '/../inc/restriction.php';

class BillingTab extends APctpWindowTab
{

    public function __construct(PctpWindowSettings $settings)
    {
        $this->script = file_get_contents(__DIR__ . '/../sql/billing.sql');
        $newTag = isset($settings->config['enable_unified_table']) && $settings->config['enable_unified_table'] ? '_new' : '';
        $this->extractScript = file_get_contents(__DIR__ . '/../sql/extract/billing_extract_qry'.$newTag.'.sql');
        $this->preFetchRefreshScripts = [file_get_contents(__DIR__ . '/../sql/refresh_custom_tables/refresh_billing_extract.sql')];
        $this->columnDefinitions = [
            new ColumnDefinition('Attachment', 'Attachment', ColumnType::TEXT),
            new ColumnDefinition('PODNum', 'POD Number', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('BookingDate', 'Booking Date', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('BookingId', 'Booking Number', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('PODSONum', 'Sales Order based on POD', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('DocNum', 'SAP ID (AR Invoice)', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('CustomerName', 'Client Name', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('SAPClient', 'SAP Client Code', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('GroupProject', 'Group Project / Location (SAP)', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('PlateNumber', 'Plate Number', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('VehicleTypeCap', 'Vehicle Type & Capacity', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'vehicleTypeCapOptions'),
            new ColumnDefinition('DeliveryOrigin', 'Delivery Origin', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('Destination', 'Destination', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('DeliveryStatus', 'Delivery Status', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'deliveryStatusOptions'),
            new ColumnDefinition('DeliveryDatePOD', 'Delivery Complete Date (PER POD)', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('NoOfDrops', 'No Of Drops', ColumnType::INT, ColumnViewType::AUTO),
            new ColumnDefinition('TripType', 'Trip Type', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'tripTypeOptions'),
            new ColumnDefinition('TripTicketNo', 'Trip Ticket #', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('WaybillNo', 'Waybill #', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('ShipmentManifestNo', 'Shipment No / Manifest No', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('DeliveryReceiptNo', 'Delivery Receipt No', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('SeriesNo', 'Series #', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('OtherPODDoc', 'Other POD Document', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('RemarksPOD', 'Remarks (POD)', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('ClientReceivedDate', 'Client Received Date', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('ActualHCRecDate', 'Actual HC Inteluck Received Date', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('PODinCharge', 'POD in Charge', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('VerifiedDateHC', 'Verified Date Hard Copy GOOD', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('PODStatusDetail', 'POD Status (Detail)', ColumnType::TEXT, ColumnViewType::AUTO, 'podStatusOptions'),
            new ColumnDefinition('PTFNo', 'PTF No', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('DateForwardedBT', 'Date Forwared to BT', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('BillingDeadline', 'Billing Deadline', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('BillingStatus', 'Billing Status', ColumnType::ALPHANUMERIC, ColumnViewType::DROPDOWN, 'billingStatusOptions', true),
            new ColumnDefinition('ServiceType', 'Service Type', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('InvoiceNo', 'SI #', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('BillingTeam', 'Billing Team in Charge', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('BTRemarks', 'BT Remarks', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('GrossInitialRate', 'Gross Initial Rate', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('Demurrage', 'Demurrage', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('AddCharges', 'Additional Charges', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('ActualBilledRate', 'Actual Billed Amount Main Rates', ColumnType::FLOAT),
            new ColumnDefinition('RateAdjustments', 'Rate Adjustments', ColumnType::FLOAT),
            new ColumnDefinition('ActualDemurrage', 'Actual Demurrage', ColumnType::FLOAT),
            new ColumnDefinition('ActualAddCharges', 'Actual Additional Charges', ColumnType::FLOAT),
            new ColumnDefinition('_TotalRecClients', 'Total Receivable from Clients, per SI Recon with BR', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('Checking', 'Checking', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('CWT2307', 'CWT 2307', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('TotalAR', 'Total AR (Stand Alone)', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('_VarAR', 'Variance', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('SOBNumber', 'SOB Number', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('OutletNo', 'Outlet No. (Criteria for GetColaRates)', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('CBM', 'CBM (Cubic meter) - Based on SI/DR', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('SI_DRNo', 'Sales Invoice No/ Delivery Receipt No', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('DeliveryMode', 'Delivery Mode', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('SourceWhse', 'Source Whse - Based on DTT Stamp', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('DestinationClient', 'Destination (Client\'s Customer)', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('TotalInvAmount', 'Total Invoice Amount', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('SONo', 'SO No - Listed on Delivery Receipt', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('NameCustomer', 'Name of Customer', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('CategoryDR', 'Category - Listed on Delivery Receipt', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('ForwardLoad', 'Forward Load', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('BackLoad', 'Back Load', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('IDNumber', 'ID Number', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('TypeOfAccessorial', 'Type of Accessorial', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'typeOfAccessorialOptions'),
            new ColumnDefinition('Status', 'Approval status of Accessorial', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('TimeInEmptyDem', 'Time In (Empty Demurrage)', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('TimeOutEmptyDem', 'Time Out (Empty Demurrage)', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('VerifiedEmptyDem', 'Verified Empty Demurrage', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('TimeInLoadedDem', 'Time In (Loaded Demurrage)', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('TimeOutLoadedDem', 'Time Out (Loaded Demurrage)', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('VerifiedLoadedDem', 'Verified Loaded Demurrage', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('Remarks', 'Remarks', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('TimeInAdvLoading', 'Time In (Advance Loading)', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('DayOfTheWeek', 'Day Of The Week', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('TimeIn', 'Time In', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('TimeOut', 'Time Out', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('TotalExceed', 'Total No. Exceed (Overtime)', ColumnType::INT, ColumnViewType::AUTO),
            new ColumnDefinition('ODOIn', 'ODO In', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('ODOOut', 'ODO Out', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('TotalUsage', 'Total Usage', ColumnType::INT, ColumnViewType::AUTO),
        ];
        $this->defaultFetchFilterClause = $newTag === '' ? '' : " ( pod.U_PODStatusDetail LIKE '%Verified%' OR pod.U_PODStatusDetail LIKE '%ForAdvanceBilling%' ) ";
        $this->unifiedAliasColumns = $newTag === '' ? [] : [
            'DisableTableRow' => 'bi_DisableTableRow',
            'DisableSomeFields' => 'bi_DisableSomeFields',
            ' Code ' => ' bi_Code ',
            'U_PODNum' => 'bi_U_PODNum',
            'U_BillingTeam' => 'bi_U_BillingTeam',
            'U_RateAdjustments' => 'bi_U_RateAdjustments',
            'U_ActualDemurrage' => 'bi_U_ActualDemurrage',
            'U_BackLoad' => 'po_U_BackLoad',
        ];
        $this->relatedTables = [
            new RelatedTable('podTab', 'BookingId', 'BookingNumber'),
            new RelatedTable('tpTab', 'BookingId', 'BookingId'),
        ];
        $this->notSameColumns = [
            'PricingTab' => [
                'Demurrage',
            ],
            'PodTab' => [
                'DocNum'
            ],
            'TpTab' => [
                'DocNum',
                'RateAdjustments',
                'ActualDemurrage'
            ]
        ];
        $this->searchableFields = [
            'DocNum',
            'TripTicketNo',
            'WaybillNo',
            'ShipmentManifestNo',
            'DeliveryReceiptNo',
            'SeriesNo',
            'OtherPODDoc',
            'PODSONum'
        ];
        $this->fieldsFindOptions = [
            'SAPClient' => [
                'alias' => 'pod',
                'field' => 'SAPClient',
            ],
            'BookingDate' => [
                'alias' => 'pod',
                'field' => 'BookingDate',
                'needColumnFormat' => true,
                'involveInFindText' => true,
            ],
            'TripTicketNo' => [
                'alias' => 'pod',
                'field' => 'TripTicketNo',
                'involveInFindText' => true,
            ],
            'WaybillNo' => [
                'alias' => 'pod',
                'field' => 'WaybillNo',
                'involveInFindText' => true,
            ],
            'ShipmentManifestNo' => [
                'alias' => 'pod',
                'field' => 'ShipmentNo',
                'involveInFindText' => true,
            ],
            'DeliveryReceiptNo' => [
                'alias' => 'pod',
                'field' => 'DeliveryReceiptNo',
                'involveInFindText' => true,
            ],
            'SeriesNo' => [
                'alias' => 'pod',
                'field' => 'SeriesNo',
                'involveInFindText' => true,
            ],
            'OtherPODDoc' => [
                'alias' => 'pod',
                'field' => 'OtherPODDoc',
                'involveInFindText' => true,
            ],
            'BillingStatus' => [
                'alias' => ['BE', 'T0'],
                'field' => 'BillingStatus',
                'involveInFindText' => true,
                'notInMethodTrack' => 'getAttachmentObjs'
            ],
        ];
        $this->excludeFromWildCardSearch = [
            'BillingStatus',
            'PODSONum'
        ];
        $this->sapDocumentStructureTypes = [
            SAPDocumentStructureType::SALES_ORDER->name(),
            SAPDocumentStructureType::AR_INVOICE->name(),
        ];
        $this->fieldConstants = [
            new FieldConstant('GroupProject', 'GroupLocation')
        ];
        $this->fieldDatesToFormat = ['DateForwardedBT', 'BillingDeadline'];
        $this->foreignFields = ['Attachment', 'TripTicketNo', 'InvoiceNo', 'ServiceType', 'TotalInvAmount'];
        $this->disableSomeFields = [
            'DisableSomeFields' => [
                'BillingStatus'
            ]
        ];
        parent::__construct(
            'Code',
            $settings->tabTables[lcfirst(get_class($this))],
            $settings
        );
        $this->columnValidations = [
            'BillingStatus' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => ['SenttoBT'],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => ['PTFNo'],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [null, '', 0],
                                'result' => ''
                            ]
                        ],
                        (object)[
                            'values' => ['ReturntoPOD'],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'promptMessage2Buttons2ReturnBools',
                                        'arg' => (object)[
                                            'title' => 'PCTP WINDOW',
                                            'message' => "This will change the POD Status Detail from 'Verified' to 'Ongoing verification'. Proceed?",
                                            'button1Label' => 'Yes',
                                            'button2Label' => 'No',
                                            'callback' => 'changeFieldValueFromOtherTab',
                                            'prop' => (object)[
                                                'tab' => 'billing',
                                                'refField' => 'PODNum',
                                                'otherTab' => 'pod',
                                                'foreignField' => 'Code',
                                                'field' => 'PODStatusDetail',
                                                'value' => 'OngoingVerification',
                                                'doRefreshDataRow' => true,
                                            ]
                                        ],
                                    ]
                                ]
                            ],
                            'relatedUpdates' => [
                                [
                                    'tab' => 'pod',
                                    'fields' => [
                                        'PODStatusDetail' => 'OngoingVerification',
                                        'BillingStatus' => 'ReturntoPOD',
                                    ]
                                ]
                            ]
                        ],
                        (object)[
                            'values' => ['ReturntoPOD'],
                            'for' => ['', 'update'],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTab',
                                        'arg' => (object)[
                                            'tab' => 'billing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'pod',
                                            'foreignField' => 'Code',
                                            'field' => 'BillingStatus',
                                            'value' => 'self',
                                        ]
                                    ]
                                ]
                            ]
                        ],
                        (object)[
                            'values' => ['ReturntoPOD'],
                            'for' => ['update'],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'deleteRowFromTable',
                                        'arg' => (object)[
                                            'tab' => 'billing'
                                        ]
                                    ]
                                ]
                            ]
                        ],
                        (object)[
                            'values' => ['Billed'],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => ['DocNum'],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [null, '', 0],
                                'exemptions' => [
                                    'allOtherFieldMatch' => [
                                        [
                                            'field' => 'SAPClient',
                                            'value' => '@SAPClientBillingLogicExemption'
                                        ]
                                    ]
                                ],
                                'result' => (object)[
                                    'failed' => (object)[
                                        'message' => "AR Invoice should be created first before tagging as Billed",
                                        'callback' => 'clearElementValue',
                                        'ignorable' => false
                                    ]
                                ]
                            ]
                        ],
                    ]
                ]
            ]
        ];
    }

    protected function postProcessPostingTransaction(object $args): mixed
    {
        if ($args->valid) {
            switch ($args->structure->objectType) {
                case SAPDocumentStructureType::SALES_ORDER:
                    return $this->postProcessPostingSalesOrder($args);
                case SAPDocumentStructureType::AR_INVOICE:
                    return $this->postProcessPostingArInvoice($args);
                default:
                    # code...
                    break;
            }
        }
        return $args;
    }

    private function postProcessPostingArInvoice(object $args): mixed
    {
        $appendedArgs = (array)$args;
        $appendedArgs['rData'] = [];
        $addedARNum = $args->docNum;
        foreach ($args->sapObj->lines as $line) {
            $billingCode = $line->rowData->Code;
            $appendedArgs['rData'][] = $this->processRelatedDataRowsForAR($billingCode, $addedARNum);
        }
        return (object)$appendedArgs;
    }

    private function processRelatedDataRowsForAR(string $billingCode, string $addedARNum): object
    {
        $queries = [];
        $BillingTeam = $_SESSION['SESS_USERCODE'];
        $queries[] = "UPDATE $this->tableName SET U_DocNum = $addedARNum, U_BillingTeam = '$BillingTeam' WHERE Code = '$billingCode'";
        $rows = [];
        $dataRow = $this->getRowReference((object)[ 'Code' => $billingCode ]);
        $rows[] = (object)[
            'BookingId' => $dataRow->BookingId,
            'tab' => 'billing',
            'userInfo' => [
                'sessionId' => session_id(),
                'userName' => $_SESSION['SESS_NAME'],
                'userId' => $_SESSION['SESS_USERID'],
            ],
            'old' => [
                'DocNum' => $dataRow->DocNum,
                'BillingTeam' => $dataRow->BillingTeam,
            ],
            'new' => [
                'DocNum' => $addedARNum,
                'BillingTeam' => $BillingTeam,
            ],
        ];
        $result = SAPAccessManager::getInstance()->runUpdateNativeQuery($queries);
        SAPAccessManager::getInstance()->log($rows, [], LogEventType::CREATE_AR);
        $appendedArgs['postProcessResultData'] = $result;
        $rDataRows = [];
        $rDataRows[] = (object)[
            'tab' => 'billing',
            'rows' => [
                [
                    'rowCode' => 'billing' . $billingCode,
                    'Code' => $billingCode,
                    'props' => [
                        'DocNum' => $addedARNum,
                        'BillingTeam' => $BillingTeam,
                    ]
                ]
            ]
        ];
        $appendedArgs['rDataRows'] = $rDataRows;
        return (object)$appendedArgs;
    }

    private function postProcessPostingSalesOrder(object $args): mixed
    {
        $appendedArgs = (array)$args;
        $appendedArgs['rData'] = [];
        $addedSONum = $args->docNum;
        foreach ($args->sapObj->lines as $line) {
            $billingCode = $line->rowData->Code;
            $bookingId = trim($line->ItemCode);
            $appendedArgs['rData'][] = $this->processRelatedDataRowsForSO($billingCode, $addedSONum, $bookingId);
        }
        return (object)$appendedArgs;
    }

    private function processRelatedDataRowsForSO(string $billingCode, string $addedSONum, string $bookingId): object
    {
        $podTable = $this->settings->tabTables['podTab'];
        $tpTable = $this->settings->tabTables['tpTab'];
        $queries = [];
        $rows = [];
        $relatedQueries = [];
        $queries[] = "UPDATE $this->tableName SET U_PODSONum = $addedSONum WHERE Code = '$billingCode'";
        $rows[] = (object)[
            'BookingId' => $bookingId,
            'tab' => 'billing',
            'userInfo' => [
                'sessionId' => session_id(),
                'userName' => $_SESSION['SESS_NAME'],
                'userId' => $_SESSION['SESS_USERID'],
            ],
            'old' => [
                'PODSONum' => $this->getRowReference((object)[ 'Code' => $billingCode ])->PODSONum,
            ],
            'new' => [
                'PODSONum' => $addedSONum,
            ],
        ];
        $relatedQueries[$bookingId] = "UPDATE $tpTable SET U_PODSONum = $addedSONum WHERE U_BookingId = '$bookingId'";
        // $queries[] = "UPDATE $podTable SET U_DocNum = $addedSONum WHERE Code = '$bookingId'";
        $queries[] = "UPDATE $tpTable SET U_PODSONum = $addedSONum WHERE U_BookingId = '$bookingId'";
        $result = SAPAccessManager::getInstance()->runUpdateNativeQuery($queries);
        SAPAccessManager::getInstance()->log($rows, $relatedQueries, LogEventType::CREATE_SO);
        $appendedArgs['postProcessResultData'] = $result;
        $rDataRows = [];
        $rDataRows[] = (object)[
            'tab' => 'billing',
            'rows' => [
                [
                    'Code' => $billingCode,
                    'props' => [
                        'PODSONum' => $addedSONum,
                    ]
                ]
            ]
        ];
        $model = PctpWindowFactory::getObject('PctpWindowController', $_SESSION)->model;
        // $relatedTab = $model->podTab;
        // $fetchRows = array_values(array_filter($relatedTab->tableRows, fn($z) => $z->Code === $podNum));
        // if ((bool)$fetchRows) {
        //     $rDataRows[] = (object)[
        //         'tab' => 'pod',
        //         'rows' => [
        //             [
        //                 'Code' => $podNum,
        //                 'props' => [
        //                     'DocNum' => $addedSONum
        //                 ]
        //             ]
        //         ]
        //     ];
        // }
        $relatedTab = $model->tpTab;
        $fetchRows = array_values(array_filter($relatedTab->tableRows, fn ($z) => $z->PODNum === $bookingId));
        if ((bool)$fetchRows) {
            $rDataRows[] = (object)[
                'tab' => 'tp',
                'rows' => [
                    [
                        'Code' => $fetchRows[0]->Code,
                        'props' => [
                            'PODSONum' => $addedSONum
                        ]
                    ]
                ]
            ];
        }
        $appendedArgs['rDataRows'] = $rDataRows;
        return (object)$appendedArgs;
    }

    protected function postFetchProcessRows(array $rows): array
    {
        return $rows;
    }

    protected function preUpdateProcessRows(PctpWindowModel &$model, array $rows): array
    {
        return $rows;
    }

    protected function postUpdateProcessRows(PctpWindowModel &$model, array $rows)
    {
        // code here...
    }
}
