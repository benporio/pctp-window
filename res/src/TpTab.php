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

class TpTab extends APctpWindowTab
{

    public function __construct(PctpWindowSettings $settings)
    {
        $this->script = file_get_contents(__DIR__ . '/../sql/tp.sql');
        $this->extractScript = file_get_contents(__DIR__ . '/../sql/extract/tp_extract_qry.sql');
        $this->preFetchRefreshScripts = [
            file_get_contents(__DIR__ . '/../sql/refresh_custom_tables/refresh_tp_formula.sql'),
            file_get_contents(__DIR__ . '/../sql/refresh_custom_tables/refresh_tp_extract.sql')
        ];
        $this->columnDefinitions = [
            new ColumnDefinition('Attachment', 'Attachment', ColumnType::TEXT),
            new ColumnDefinition('PODNum', 'POD Number', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('Code', 'Code', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('BookingId', 'Booking ID', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('BookingDate', 'Booking Date', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('PODSONum', 'Sales Order based on POD', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('DocNum', 'SAP ID (AP Invoice)', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('Paid', 'Paid AP Invoice', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('ClientName', 'Client Name', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('GroupProject', 'Group Project / Location (SAP)', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('TruckerName', 'Trucker Name', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('TruckerSAP', 'Trucker SAP Code', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('PlateNumber', 'Plate Number', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('VehicleTypeCap', 'Vehicle Type & Capacity', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'vehicleTypeCapOptions'),
            new ColumnDefinition('DeliveryOrigin', 'Delivery Origin', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('ISLAND', 'ISLAND (ORIGIN)', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'islandsOptions'),
            new ColumnDefinition('Destination', 'Destination', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('ISLAND_D', 'ISLAND (DESTINATION)', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'islandsOptions'),
            new ColumnDefinition('IFINTERISLAND', 'if Interisland', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'yesNoOptions'),
            new ColumnDefinition('DeliveryStatus', 'Delivery Status', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'deliveryStatusOptions'),
            new ColumnDefinition('DeliveryDatePOD', 'Delivery Complete Date (PER POD)', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('NoOfDrops', 'No of Drops', ColumnType::INT, ColumnViewType::AUTO),
            new ColumnDefinition('TripType', 'Trip Type', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'tripTypeOptions'),
            new ColumnDefinition('Remarks2', 'Remarks', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('TripTicketNo', 'Trip Ticket No', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('WaybillNo', 'Waybill #', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('ShipmentManifestNo', 'Shipment No. / Manifest No.', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('DeliveryReceiptNo', 'Delivery Receipt No', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('SeriesNo', 'Series #', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('OtherPODDoc', 'Other POD Document', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('RemarksPOD', 'Remarks (POD)', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('Receivedby', 'Received by', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('ClientReceivedDate', 'Client Received Date', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('ActualDateRec_Intitial', 'Actual date received Soft copy (Initial)', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('InitialHCRecDate', 'Initial HC Inteluck Received Date', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('ActualHCRecDate', 'Actual HC Inteluck Received Date', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('DateReturned', 'Date Returned', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('PODinCharge', 'POD in Charge', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('VerifiedDateHC', 'Verified Date Hard Copy GOOD', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('TPStatus', 'TP Status', ColumnType::ALPHANUMERIC, ColumnViewType::DROPDOWN, 'tpStatusOptions', true),
            new ColumnDefinition('TPincharge', 'TP in-charge', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('Aging', 'Aging', ColumnType::INT, ColumnViewType::AUTO),
            new ColumnDefinition('GrossTruckerRates', 'Gross Trucker Rates', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('GrossTruckerRatesN', 'Gross Trucker Rates (Non-VAT)', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('RateBasis', 'Rate Basis', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('TaxType', 'Tax Type', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('Demurrage', 'Demurrage', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('AddtlDrop', 'Addt\'l Drop', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('BoomTruck', 'Boom Truck', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('Manpower', 'Manpower', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('BackLoad', 'Back Load', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('Addtlcharges', 'Additional Charges', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('DemurrageN', 'Demurrage - Considering NON VAT Rate', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('AddtlChargesN', 'Additional Charges Considering NON VAT Rate', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('ActualRates', 'Actual rates charged by trucker', ColumnType::FLOAT),
            new ColumnDefinition('RateAdjustments', 'Rate Adjustments', ColumnType::FLOAT),
            new ColumnDefinition('ActualDemurrage', 'Actual Approved Demurrage', ColumnType::FLOAT),
            new ColumnDefinition('ActualCharges', 'Actual Addtional Charges', ColumnType::FLOAT),
            new ColumnDefinition('BoomTruck2', 'Boom Truck', ColumnType::FLOAT),
            new ColumnDefinition('OtherCharges', 'Other Charges', ColumnType::FLOAT),
            new ColumnDefinition('TotalSubPenalty', 'Total Submission Penalty', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('TotalPenaltyWaived', 'Total Penalty Waived', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('_TotalPenalty', 'Total Penalty', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('CAandDP', 'Cash advances/Down payment', ColumnType::FLOAT),
            new ColumnDefinition('Interest', 'Interest', ColumnType::FLOAT),
            new ColumnDefinition('OtherDeductions', 'Other deductions', ColumnType::FLOAT),
            new ColumnDefinition('_TOTALDEDUCTIONS', 'TOTAL DEDUCTIONS', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('REMARKS1', 'REMARKS', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('_TotalPayable', 'Total Payable to Truckers', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('EWT2307', 'EWT 2307', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('TotalAP', 'Total AP (Stand Alone)', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('_VarTP', 'Variance', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('TotalPayableRec', 'Total Payable (Receivable from Trucker)', ColumnType::FLOAT),
            new ColumnDefinition('PVNo', 'Payment Voucher Number', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('ORRefNo', 'OR Reference Number', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('ActualPaymentDate', 'Actual Payment Date', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('PaymentReference', 'Payment Reference', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('PaymentStatus', 'Payment Status', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('Remarks', 'Remarks', ColumnType::TEXT),
            new ColumnDefinition('APInvLineNum', 'AP Inv Line Number', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
        ];
        $this->similarFields = [
            'TruckerSAP' => ['SAPTrucker']
        ];
        $this->notSameColumns = [
            'PricingTab' => [
                'RateBasis',
                'Demurrage',
                'AddtlDrop',
                'BoomTruck',
                'Manpower',
            ],
            'PodTab' => [
                'DocNum'
            ],
            'BillingTab' => [
                'DocNum',
                'RateAdjustments',
                'ActualDemurrage'
            ]
        ];
        $this->sapDocumentStructureTypes = [
            SAPDocumentStructureType::AP_INVOICE->name(),
        ];
        $this->fieldDatesToFormat = ['Aging'];
        $this->excludeFromWildCardSearch = [
            'PODSONum'
        ];
        $this->foreignFields = [
            'Attachment',
            'Cancelled',
            'Paid',
            'GroupProject',
            'PlateNumber',
            'VehicleTypeCap',
            'DeliveryOrigin',
            'ISLAND',
            'Destination',
            'ISLAND_D',
            'IFINTERISLAND',
            'NoOfDrops',
            'TripType',
            'Remarks2',
            'RemarksPOD',
            'Receivedby',
            'ClientReceivedDate',
            'ActualDateRec_Intitial',
            'InitialHCRecDate',
            'ActualHCRecDate',
            'DateReturned',
            'PODinCharge',
            'VerifiedDateHC'
        ];
        $this->searchableFields = [
            'DocNum',
            'TripTicketNo',
            'WaybillNo',
            'DeliveryReceiptNo',
            'SeriesNo',
            'OtherPODDoc',
            'PODSONum'
        ];
        $this->fieldsFindOptions = [
            'PODSONum' => [
                'alias' => 'billing',
                'field' => 'PODSONum',
                'involveInFindText' => true,
            ],
            'OtherPODDoc' => [
                'alias' => 'pod',
                'field' => 'OtherPODDoc',
                'involveInFindText' => true,
            ],
            'SeriesNo' => [
                'alias' => 'pod',
                'field' => 'SeriesNo',
                'involveInFindText' => true,
            ],
            'DeliveryReceiptNo' => [
                'alias' => 'pod',
                'field' => 'DeliveryReceiptNo',
                'involveInFindText' => true,
            ],
            'WaybillNo' => [
                'alias' => 'pod',
                'field' => 'WaybillNo',
                'involveInFindText' => true,
            ],
            'TripTicketNo' => [
                'alias' => 'pod',
                'field' => 'TripTicketNo',
                'involveInFindText' => true,
            ],
            'SAPClient' => [
                'alias' => 'pod',
                'field' => 'SAPClient',
                'needColumnFormat' => true,
            ],
            'TruckerSAP' => [
                'alias' => 'pod',
                'field' => 'SAPTrucker',
                'needColumnFormat' => true,
                'involveInFindText' => true
            ],
            'TotalAP' => [
                'alias' => 'TF',
                'field' => 'TotalAP',
                'needColumnFormat' => true,
                'involveInOrderBy' => true,
            ],
            'VarTP' => [
                'alias' => 'TF',
                'field' => 'VarTP',
                'needColumnFormat' => true,
                'involveInOrderBy' => true,
            ],
            'ClientSubOverdue' => [
                'alias' => 'TF',
                'field' => 'ClientSubOverdue',
                'needColumnFormat' => true,
                'involveInOrderBy' => true,
            ],
            'ClientPenaltyCalc' => [
                'alias' => 'TF',
                'field' => 'ClientPenaltyCalc',
                'needColumnFormat' => true,
                'involveInOrderBy' => true,
            ],
            'InteluckPenaltyCalc' => [
                'alias' => 'TF',
                'field' => 'InteluckPenaltyCalc',
                'needColumnFormat' => true,
                'involveInOrderBy' => true,
            ],
            'LostPenaltyCalc' => [
                'alias' => 'TF',
                'field' => 'LostPenaltyCalc',
                'needColumnFormat' => true,
                'involveInOrderBy' => true,
            ],
            'TotalSubPenalty' => [
                'alias' => 'TF',
                'field' => 'TotalSubPenalty',
                'needColumnFormat' => true,
                'involveInOrderBy' => true,
            ],
            'TotalPenaltyWaived' => [
                'alias' => 'TF',
                'field' => 'TotalPenaltyWaived',
                'needColumnFormat' => true,
                'involveInOrderBy' => true,
            ],
            'DocNum' => [
                'alias' => 'TF',
                'field' => 'DocNum',
                'needColumnFormat' => true,
                'involveInOrderBy' => true,
            ],
            'Paid' => [
                'alias' => 'TF',
                'field' => 'Paid',
                'needColumnFormat' => true,
                'involveInOrderBy' => true,
            ],
            'BookingDate' => [
                'alias' => 'pod',
                'field' => 'BookingDate',
                'needColumnFormat' => true,
                'involveInFindText' => true,
            ],
        ];
        $this->disableSomeFields = [
            'DisableSomeFields' => [
                'TPStatus',
                'REMARKS1',
                'TotalPayableRec',
                'ORRefNo',
                'Remarks'
            ]
        ];
        parent::__construct(
            'Code',
            $settings->tabTables[lcfirst(get_class($this))],
            $settings
        );
    }

    protected function postFetchProcessRows(array $rows): array
    {
        return $rows;
    }

    protected function postProcessPostingTransaction(object $args): mixed
    {
        if ($args->valid) {
            return $this->postProcessPostingApInvoice($args);
        }
        return $args;
    }

    private function postProcessPostingApInvoice(object $args): mixed
    {
        $appendedArgs = (array)$args;
        $appendedArgs['rData'] = [];
        $addedAPNum = $args->docNum;
        foreach ($args->sapObj->lines as $line) {
            $tpCode = $line->rowData->Code;
            $appendedArgs['rData'][] = $this->processRelatedDataRowsForAP($tpCode, $addedAPNum);
        }
        return (object)$appendedArgs;
    }

    private function processRelatedDataRowsForAP(string $tpCode, string $addedAPNum): object
    {
        $queries = [];
        $queries[] = "UPDATE $this->tableName SET U_DocNum = $addedAPNum WHERE Code = '$tpCode'";
        $rows = [];
        $dataRow = $this->getRowReference((object)[ 'Code' => $tpCode ]);
        $rows[] = (object)[
            'BookingId' => $dataRow->BookingId,
            'tab' => 'tp',
            'userInfo' => [
                'sessionId' => session_id(),
                'userName' => $_SESSION['SESS_NAME'],
                'userId' => $_SESSION['SESS_USERID'],
            ],
            'old' => [
                'DocNum' => $dataRow->DocNum,
            ],
            'new' => [
                'DocNum' => $addedAPNum,
            ],
        ];
        $result = SAPAccessManager::getInstance()->runUpdateNativeQuery($queries);
        SAPAccessManager::getInstance()->log($rows, [], LogEventType::CREATE_AP);
        $appendedArgs['postProcessResultData'] = $result;
        $rDataRows = [];
        $rDataRows[] = (object)[
            'tab' => 'tp',
            'rows' => [
                [
                    'Code' => $tpCode,
                    'props' => [
                        'DocNum' => $addedAPNum
                    ]
                ]
            ]
        ];
        $appendedArgs['rDataRows'] = $rDataRows;
        return (object)$appendedArgs;
    }

    protected function preUpdateProcessRows(PctpWindowModel &$model, array $rows): array
    {
        return $rows;
    }

    protected function postUpdateProcessRows(PctpWindowModel &$model, array $rows)
    {
        // code here
    }
}
