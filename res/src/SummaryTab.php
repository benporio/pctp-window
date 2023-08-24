<?php

require_once __DIR__ . '/../inc/restriction.php';

class SummaryTab extends APctpWindowTab
{
    public function __construct(PctpWindowSettings $settings)
    {
        $this->script = file_get_contents(__DIR__ . '/../sql/summary.sql');
        $this->extractScript = file_get_contents(__DIR__ . '/../sql/extract/summary_extract_qry.sql');
        $this->preFetchRefreshScripts = [file_get_contents(__DIR__ . '/../sql/refresh_custom_tables/refresh_summary_extract.sql')];
        $this->columnDefinitions = [
            new ColumnDefinition('BookingNumber', 'Booking Number', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('BookingDate', 'Booking Date', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('ClientName', 'Client Name', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('SAPClient', 'Client Code', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('ServiceType', 'Service Type', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('ClientVatStatus', 'VAT Status', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('TruckerName', 'Trucker Name', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('SAPTrucker', 'SAP Trucker Code', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('TruckerVatStatus', 'VAT Status', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('VehicleTypeCap', 'Vehicle Type & Capacity', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'vehicleTypeCapOptions'),
            new ColumnDefinition('DeliveryOrigin', 'Delivery Origin', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('ISLAND', 'ISLAND (ORIGIN)', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'islandsOptions'),
            new ColumnDefinition('Destination', 'Destination', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('ISLAND_D', 'ISLAND (DESTINATION)', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'islandsOptions'),
            new ColumnDefinition('IFINTERISLAND', 'if Interisland', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'yesNoOptions'),
            new ColumnDefinition('DeliveryStatus', 'Delivery Status', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'deliveryStatusOptions'),
            new ColumnDefinition('DeliveryDateDTR', 'Delivery Complete Date (PER DTR)', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('DeliveryDatePOD', 'Delivery Complete Date (PER POD)', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('Remarks', 'Remarks', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('WaybillNo', 'Waybill #', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('PODStatusDetail', 'POD Status (Detail)', ColumnType::TEXT, ColumnViewType::AUTO, 'podStatusOptions'),
            new ColumnDefinition('ClientReceivedDate', 'Client Received Date', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('ActualDateRec_Intitial', 'Actual date received Soft copy (Initial)', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('InitialHCRecDate', 'Initial HC Inteluck Received Date', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('ActualHCRecDate', 'Actual HC Inteluck Received Date', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('DateReturned', 'Date Returned', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('VerifiedDateHC', 'Verified Date Hard Copy GOOD', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('PTFNo', 'PTF (POD Transmitall Form) #', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('DateForwardedBT', 'Date Forwarded to BT (Hard Copy)', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('GrossClientRates', 'Gross Client Rates', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('GrossClientRatesTax', 'Gross Client Rates (Based on tax type)', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('GrossTruckerRates', 'Gross Trucker', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('GrossTruckerRatesTax', 'Gross Trucker (Based on tax type)', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('GrossProfitNet', 'Gross Profit', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('TotalInitialClient', 'Total Client Rate', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('TotalInitialTruckers', 'Total Trucker Cost', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('TotalGrossProfit', 'Total Gross Profit', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('BillingStatus', 'Billing Status', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'billingStatusOptions'),
            new ColumnDefinition('InvoiceNo', 'SI Reference', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('PODSONum', 'SAP ID (Sales Order)', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('ARDocNum', 'SAP ID (AR Invoice)', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('TotalRecClients', 'Total Receivable from Clients, per SI Recon with BR', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('TotalAR', 'Total AR (Stand Alone)', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('VarAR', 'Variance', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('PODStatusPayment', 'Collection Status', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('PaymentReference', 'Collection Reference', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('PaymentStatus', 'Payment to Trucker Status', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('APDocNum', 'AP Invoice', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('PVNo', 'Payment Voucher Number', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('ProofOfPayment', 'Proof of Payment', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('TotalPayable', 'Total Payable to Truckers', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('TotalAP', 'Total AP (Stand Alone)', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('VarTP', 'Variance', ColumnType::FLOAT, ColumnViewType::AUTO),
        ];
        $this->foreignFields = [
            'ClientVatStatus',
            'TruckerVatStatus',
            'GrossClientRates',
            'GrossClientRatesTax',
            'GrossTruckerRates',
            'GrossTruckerRatesTax',
            'GrossProfitNet',
            'TotalInitialClient',
            'TotalInitialTruckers',
            'TotalGrossProfit',
            'BillingStatus',
            'PaymentReference',
            'PaymentStatus',
            'APDocNum',
            'ProofOfPayment',
            'InvoiceNo',
            'ARDocNum',
            'TotalRecClients',
            'TotalAR',
            'VarAR',
            'PODSONum',
            'PVNo'
        ];
        $this->excludeFromWildCardSearch = [
            'InvoiceNo',
            'BillingStatus',
            'PODSONum'
        ];
        $this->searchableFields = [
            'PODSONum',
            'InvoiceNo',
            'PVNo'
        ];
        $this->fieldsFindOptions = [
            'PODSONum' => [
                'alias' => 'billing',
                'field' => 'PODSONum',
                'involveInFindText' => true,
            ],
            'BillingStatus' => [
                'alias' => ['BE', 'T0'],
                'field' => 'BillingStatus',
                'involveInFindText' => true,
                'notInMethodTrack' => 'getAttachmentObjs'
            ],
            'InvoiceNo' => [
                'alias' => 'BE',
                'field' => 'InvoiceNo',
                'involveInFindText' => true,
                'notInMethodTrack' => 'getAttachmentObjs'
            ],
        ];
        $this->columnsNeedUtf8Conversion = ['DeliveryOrigin'];
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
        return $args;
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
