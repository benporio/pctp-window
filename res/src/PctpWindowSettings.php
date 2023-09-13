<?php

require_once __DIR__ . '/../inc/restriction.php';

class PctpWindowSettings extends ASerializableClass
{
    public int $fetchRowLimit = -1;
    public array $immutableFieldNames = ['', 'Code'];
    public string $initialBookingDateFrom = '';
    public string $initialBookingDateTo = '';
    public array $dropDownOptions;
    public array $tabTables = [
        'summaryTab' => '[@PCTP_POD]',
        'podTab' => '[@PCTP_POD]',
        'billingTab' => '[@PCTP_BILLING]',
        'tpTab' => '[@PCTP_TP]',
        'pricingTab' => '[@PCTP_PRICING]',
        'treasuryTab' => '[@PCTP_TREASURY]'
    ];
    public object $sapDocumentStructures;
    public string $uploadDirectory;
    public string $initialFilterClause = '';
    public string $defaultOrderClause = 'ORDER BY T0.U_BookingDate DESC, T0.Code DESC';
    public array $constants;
    public array $apiData;
    public string $defaultSQLColumnPrefix = 'U_';
    public string $columnValidRegexPrefix = '/(?<![\.|\'%\S+])';
    public string $defaultSQLColumnPattern = 'U_?';
    public string $defaultSQLMainTableAlias = 'T0';
    public string $notificationReceipientUserCode = 'manager';
    public array $viewOptions;
    public array $queries;
    public array $config;
    public array $preFetchRefreshScripts;

    public function __construct()
    {
        // $this->uploadDirectory = 'C:\xampp\htdocs\SAPB1Standard\modules\addon-pctp-window\uploads';
        $resultDir = SAPAccessManager::getInstance()->getRows('SELECT AttachPath FROM OADP WITH (NOLOCK)')[0];
        $this->uploadDirectory = is_null($resultDir->AttachPath) ? 'C:\xampp\htdocs\SAPB1Standard\modules\addon-pctp-window\uploads' : $resultDir->AttachPath;
        // $this->initialBookingDateFrom = date('Y-m-d', mktime(0, 0, 0, date('m'), 1, date('Y')));
        $this->initialBookingDateFrom = date('Y-m-d');
        // $this->initialBookingDateTo = date('Y-m-t', strtotime($this->initialBookingDateFrom));
        $this->initialBookingDateTo = date('Y-m-d');
        $this->viewOptions = (array)json_decode(file_get_contents(__DIR__ . '/../json/view_options.json'));
        $this->config = (array)json_decode(file_get_contents(__DIR__ . '/../json/config.json'));
        $this->preFetchRefreshScripts = [
            file_get_contents(__DIR__ . '/../sql/refresh_custom_tables/refresh_all.sql'),
            // file_get_contents(__DIR__ . '/../sql/refresh_custom_tables/refresh_billing_extract.sql'),
            // file_get_contents(__DIR__ . '/../sql/refresh_custom_tables/refresh_tp_extract.sql'),
            // file_get_contents(__DIR__ . '/../sql/refresh_custom_tables/refresh_pod_extract.sql'),
            // file_get_contents(__DIR__ . '/../sql/refresh_custom_tables/refresh_summary_extract.sql'),
            // file_get_contents(__DIR__ . '/../sql/refresh_custom_tables/refresh_pricing_extract.sql'),
        ];
        $this->queries = [
            'deliveryStatusOptions' => 'SELECT * FROM [@DELIVERYSTATUS] WITH (NOLOCK)',
            'podStatusOptions' => 'SELECT * FROM [@PODSTATUS] WITH (NOLOCK)',
            'vehicleTypeCapOptions' => 'SELECT * FROM [@VEHICLETYPEANDCAP] WITH (NOLOCK)',
            'tripTypeOptions' => 'SELECT * FROM [@TRIPTYPE] WITH (NOLOCK)',
            'typeOfAccessorialOptions' => 'SELECT * FROM [@TYPEOFACCESSORIAL] WITH (NOLOCK)',
            'billingStatusOptions' => 'SELECT * FROM [@BILLINGSTATUS] WITH (NOLOCK)',
            'rateBasisOptions' => 'SELECT * FROM [@RATEBASIS] WITH (NOLOCK)',
            'CDC_DCD' => "  SELECT
                                CONCAT('pod', pod.U_BookingNumber) AS Code,
                                ISNULL(T1.U_CDC,0) AS CDC,
                                ISNULL(T1.U_DCD,0) AS DCD
                            FROM [dbo].[@PCTP_POD] pod WITH (NOLOCK)
                            LEFT JOIN OCRD T1 ON pod.U_SAPClient = T1.CardCode
            ",
            'GroupLocation' => "    SELECT
                                        CONCAT('billing', billing.Code) AS Code,
                                        T1.U_GroupLocation AS GroupLocation
                                    FROM [dbo].[@PCTP_BILLING] billing  WITH (NOLOCK)
                                    LEFT JOIN OCRD T1 ON billing.U_SAPClient = T1.CardCode
                                    LEFT JOIN [dbo].[@PCTP_POD] pod ON billing.U_BookingId = pod.U_BookingNumber 
            ",
            'TaxType' => "  SELECT
                                CONCAT('pricing', pricing.Code) AS Code,
                                CONCAT('billing', billing.Code) AS subCode1,
                                CONCAT('tp', tp.Code) AS subCode2,
                                ISNULL(T1.VatStatus,'Y') AS 'TaxTypeClient' ,
                                ISNULL(T2.VatStatus,'Y') AS 'TaxTypeTrucker'
                            FROM [dbo].[@PCTP_PRICING] pricing WITH (NOLOCK)
                            LEFT JOIN [dbo].[@PCTP_POD] pod ON pricing.U_BookingId = pod.U_BookingNumber 
                            LEFT JOIN OCRD T1 ON T1.CardCode = pod.U_SAPClient
                            LEFT JOIN OCRD T2 ON T2.CardCode = pod.U_SAPTrucker
                            LEFT JOIN [@PCTP_BILLING] billing ON pricing.U_BookingId = billing.U_BookingId
                            LEFT JOIN [@PCTP_TP] tp ON pricing.U_BookingId = tp.U_BookingId
            ",
            'TotalInitialTruckers' => "  SELECT
                                CONCAT('pod', pod.U_BookingNumber) AS Code,
                                pod.U_BookingNumber AS PODNum,
                                ISNULL(CASE
                                    WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_GrossTruckerRates, 0)
                                    WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_GrossTruckerRates, 0) / 1.12)
                                END + CASE
                                    WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN ISNULL(pricing.U_Demurrage2, 0)
                                    WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN (ISNULL(pricing.U_Demurrage2, 0) / 1.12)
                                END + CASE
                                    WHEN ISNULL(T2.VatStatus,'Y') = 'Y' THEN (ISNULL(pricing.U_AddtlDrop2, 0) + ISNULL(pricing.U_BoomTruck2, 0) + ISNULL(pricing.U_Manpower2, 0) + ISNULL(pricing.U_Backload2, 0))
                                    WHEN ISNULL(T2.VatStatus,'Y') = 'N' THEN ((ISNULL(pricing.U_AddtlDrop2, 0) + ISNULL(pricing.U_BoomTruck2, 0) + ISNULL(pricing.U_Manpower2, 0) + ISNULL(pricing.U_Backload2, 0)) / 1.12)
                                END,0) AS TotalInitialTruckers
                            FROM [dbo].[@PCTP_POD] pod WITH (NOLOCK)
                            LEFT JOIN [dbo].[@PCTP_PRICING] pricing ON pod.U_BookingNumber = pricing.U_BookingId
                            LEFT JOIN OCRD T4 ON pod.U_SAPClient = T4.CardCode
                            LEFT JOIN OCRD T2 ON T2.CardCode = pod.U_SAPTrucker
            ",
            'SAPDateFormat' => 'SELECT DateFormat FROM OADM  WITH (NOLOCK)',
            'DateSeparator' => 'SELECT DateSep FROM OADM  WITH (NOLOCK)',
            'SAPPriceDecimal' => 'SELECT PriceDec FROM OADM  WITH (NOLOCK)',
            'CardCodes' => 'SELECT CardCode FROM OCRD  WITH (NOLOCK)',
            'CardCodeNames' => "    SELECT 
                                        CAST(CardCode as nvarchar(max)) AS CardCode, 
                                        CAST(CardName as nvarchar(max)) AS CardName, 
                                        ISNULL(CAST(U_GroupLocation as nvarchar(max)), '') AS GroupProject 
                                    FROM OCRD  WITH (NOLOCK)
            ",
            'SAPClientBillingLogicExemption' => 'SELECT Code FROM TMP_SAPClientBillingLogicExemption WITH (NOLOCK)'
        ];
        $this->dropDownOptions = [
            'deliveryStatusOptions' => SAPAccessManager::getInstance()->getRows($this->queries['deliveryStatusOptions']),
            'podStatusOptions' => SAPAccessManager::getInstance()->getRows($this->queries['podStatusOptions']),
            'vehicleTypeCapOptions' => SAPAccessManager::getInstance()->getRows($this->queries['vehicleTypeCapOptions']),
            'tripTypeOptions' => SAPAccessManager::getInstance()->getRows($this->queries['tripTypeOptions']),
            'typeOfAccessorialOptions' => SAPAccessManager::getInstance()->getRows($this->queries['typeOfAccessorialOptions']),
            'billingStatusOptions' => SAPAccessManager::getInstance()->getRows($this->queries['billingStatusOptions']),
            'rateBasisOptions' => SAPAccessManager::getInstance()->getRows($this->queries['rateBasisOptions']),
            'yesNoOptions' => [
                (object)[
                    'Code' => 'N',
                    'Name' => 'No',
                ],
                (object)[
                    'Code' => 'Y',
                    'Name' => 'Yes',
                ],
            ],
            'islandsOptions' => [
                (object)[
                    'Code' => 'LUZON',
                    'Name' => 'LUZON',
                ],
                (object)[
                    'Code' => 'VISAYAS',
                    'Name' => 'VISAYAS',
                ],
                (object)[
                    'Code' => 'MINDANAO',
                    'Name' => 'MINDANAO',
                ],
            ],
            'tpStatusOptions' => [
                (object)[
                    'Code' => 'For Payment',
                    'Name' => 'For Payment',
                ],
                (object)[
                    'Code' => 'Not Billed',
                    'Name' => 'Not Billed',
                ],
                (object)[
                    'Code' => 'Not Verified',
                    'Name' => 'Not Verified',
                ],
                (object)[
                    'Code' => 'With Rates Issue',
                    'Name' => 'With Rates Issue',
                ],
                (object)[
                    'Code' => 'Pending TRA',
                    'Name' => 'Pending TRA',
                ],
                (object)[
                    'Code' => 'Pending Request To Waive',
                    'Name' => 'Pending Request To Waive',
                ],
                (object)[
                    'Code' => 'Others',
                    'Name' => 'Others',
                ],
            ]
        ];

        $this->sapDocumentStructures = (object)[
            SAPDocumentStructureType::SALES_ORDER->name() => new SalesOrderStructure(
                SAPDocumentStructureType::SALES_ORDER,
                [
                    'DocDate' => '',
                    'DocDueDate' => 'DeliveryDatePOD',
                    'CardCode' => 'SAPClient',
                    'DocType' => '',
                ],
                [
                    'ItemCode' => 'BookingId',
                    'Quantity' => '',
                    'PriceAfterVAT' => 'TotalRecClients',
                    // 'UnitPrice'=>'TotalRecClients',
                ],
                [
                    'DocDate' => date('Y-m-d'),
                    'Quantity' => 1,
                    'DocType' => 0,
                ],
                [
                    'DocDueDate' => ColumnType::DATE,
                    'PriceAfterVAT' => ColumnType::FLOAT,
                    // 'UnitPrice' => ColumnType::FLOAT,
                ],
                [
                    'PODSONum' => [
                        'enabled' => true,
                        'columnType' => 'ALPHANUMERIC',
                        'regex' => '^(\\s+)?$', // regex for empty
                        'failedMessage' => 'Sales Order is already created'
                    ],
                    'TotalRecClients' => [
                        'enabled' => true,
                        'columnType' => 'FLOAT',
                        'invalidValues' => ['', 0, null], // regex for empty
                        'failedMessage' => 'TotalRecClients does not have valid value'
                    ],
                ],
                [],
                // [
                //     'UnitPrice' => function(mixed $thisValue): float {
                //         if (is_numeric($thisValue)) return floatval($thisValue)/1.12;
                //         return 0;
                //     }
                // ],
            ),
            SAPDocumentStructureType::AR_INVOICE->name() => new ARInvoiceStructure(
                SAPDocumentStructureType::AR_INVOICE,
                [
                    'DocDate' => '',
                    'CardCode' => 'SAPClient',
                    'DocType' => '',
                ],
                [
                    'BaseEntry' => 'PODSONum',
                    'BaseLine' => '',
                    'BaseType' => '',
                    'Quantity' => '',
                    'WTLiable' => '',
                ],
                [
                    // 'DocDate' => date('Y-m-d'),
                    'DocDate' => date('Y-m-d'),
                    'BaseLine' => 0,
                    'BaseType' => 17,
                    'Quantity' => 1,
                    'DocType' => 0,
                    'WTLiable' => 0,
                ],
                [
                    'PriceAfterVAT' => ColumnType::FLOAT,
                ],
                [
                    'DocNum' => [
                        'enabled' => true,
                        'columnType' => 'ALPHANUMERIC',
                        'regex' => '^(\\s+)?$', // regex for empty
                        // 'failedMessage' => 'AR Invoice is already created',
                        'overrideFailedMessage' => 'Cannot create AR Invoice',
                        'overrideRegex' => '^(\\s+)?\\d+(\\s+)?$',
                        'overrideLine' => [
                            'ItemCode' => 'BookingId',
                            'Quantity' => '',
                            'PriceAfterVAT' => 'RateAdjustments',
                            'WTLiable' => '',
                        ],
                    ],
                    'PODSONum' => [
                        'enabled' => true,
                        'columnType' => 'ALPHANUMERIC',
                        'regex' => '\\d+', // regex for empty
                        'failedMessage' => 'Sales Order should be created first'
                    ],
                ],
                [
                    'sapField' => 'PriceAfterVAT',
                    'part' => 'lines',
                    'caption' => 'Choose rate:',
                    'validation' => [
                        'field' => 'DocNum',
                        'validRegex' => '^(\\s+)?\\d+(\\s+)?$',
                        'failedMessage' => 'Some selected rows does not have posted AR document, multiple rates is only applicable to lines with already posted AR'
                    ],
                    'options' => [
                        [
                            'value' => 'ActualBilledRate',
                            'text' => 'Actual Billed Amount Main Rates',
                        ],
                        [
                            'value' => 'RateAdjustments',
                            'text' => 'Rate Adjustments',
                        ],
                        [
                            'value' => 'ActualDemurrage',
                            'text' => 'Actual Demurrage',
                        ],
                        [
                            'value' => 'ActualAddCharges',
                            'text' => 'Actual Additional Charges',
                        ],
                    ],
                ],
            ),
            SAPDocumentStructureType::AP_INVOICE->name() => new APInvoiceStructure(
                SAPDocumentStructureType::AP_INVOICE,
                [
                    'DocDate' => '',
                    'CardCode' => 'TruckerSAP',
                    'Comments' => 'Remarks',
                    'DocType' => '',
                ],
                [
                    'ItemCode' => 'BookingId',
                    'Quantity' => '',
                    'Price' => 'GrossTruckerRates',
                ],
                [
                    'DocDate' => date('Y-m-d'),
                    'Quantity' => 1,
                    'DocType' => 0,
                    'Comments' => '',
                ],
                [
                    'DocDate' => ColumnType::DATE,
                    'Price' => ColumnType::FLOAT,
                ],
                [
                    'DocNum' => [
                        'enabled' => true,
                        'columnType' => 'ALPHANUMERIC',
                        'regex' => '^(\\s+)?$', // regex for empty
                        // 'failedMessage' => 'AP Invoice is already created',
                        'overrideFailedMessage' => 'Cannot create AP Invoice',
                        'overrideRegex' => '^(\\s+)?\\d+(\\s+)?$',
                        'overrideLine' => [
                            'ItemCode' => 'BookingId',
                            'Quantity' => '',
                            'Price' => 'GrossTruckerRates',
                        ],
                    ],
                    'GrossTruckerRates' => [
                        'enabled' => true,
                        'columnType' => 'FLOAT',
                        'invalidValues' => ['', 0, null], // regex for empty
                        'failedMessage' => 'GrossTruckerRates does not have valid value'
                    ],
                ],
                [
                    'sapField' => 'Price',
                    'part' => 'lines',
                    'caption' => 'Choose rate:',
                    'options' => [
                        [
                            'value' => 'GrossTruckerRatesN',
                            'text' => 'Gross Trucker Rates (Non-VAT)',
                        ],
                        [
                            'value' => 'DemurrageN',
                            'text' => 'Demurrage - Considering NON VAT Rate',
                        ],
                        [
                            'value' => 'AddtlChargesN',
                            'text' => 'Additional Charges Considering NON VAT Rate',
                        ],
                        [
                            'value' => 'ActualRates',
                            'text' => 'Actual rates charged by trucker',
                        ],
                        [
                            'value' => 'RateAdjustments',
                            'text' => 'Rate Adjustments',
                        ],
                        [
                            'value' => 'ActualDemurrage',
                            'text' => 'Actual Approved Demurrage',
                        ],
                        [
                            'value' => 'ActualCharges',
                            'text' => 'Actual Addtional Charges',
                        ],
                        [
                            'value' => 'BoomTruck2',
                            'text' => 'Boom Trucks',
                        ],
                        [
                            'value' => 'OtherCharges',
                            'text' => 'Other Charges',
                        ],
                        [
                            'value' => 'TotalPenaltyWaived',
                            'text' => 'Total Penalty Waived',
                        ],
                        [
                            'value' => 'TotalPenalty',
                            'text' => 'Total Penalty',
                        ],
                    ],
                ],
            ),
        ];

        $this->initialFilterClause = 'MONTH(U_BookingDate) = ' . date("m");
        $this->constants = [
            'CDC_DCD' => SAPAccessManager::getInstance()->getRows($this->queries['CDC_DCD'] .
                "   WHERE pod.Code IS NOT NULL AND ( pod.U_BookingDate >= CONVERT(date, '$this->initialBookingDateFrom') AND pod.U_BookingDate <= CONVERT(date, '$this->initialBookingDateTo'))
                ORDER BY pod.U_BookingDate DESC, pod.Code DESC 
            "),
            'GroupLocation' => SAPAccessManager::getInstance()->getRows(
                $this->queries['GroupLocation'] .
                    "   WHERE billing.Code IS NOT NULL AND ( pod.U_BookingDate >= CONVERT(date, '$this->initialBookingDateFrom') AND pod.U_BookingDate <= CONVERT(date, '$this->initialBookingDateTo'))
                    ORDER BY pod.U_BookingDate DESC, billing.Code DESC
                ",
                new class implements IArrayProcessor
                {
                    function process(array &$array)
                    {
                        foreach ($array as $object) {
                            $object->GroupLocation = utf8_encode($object->GroupLocation);
                        }
                    }
                }
            ),
            'TaxType' => SAPAccessManager::getInstance()->getRows($this->queries['TaxType'] .
                "   WHERE pricing.Code IS NOT NULL AND ( pod.U_BookingDate >= CONVERT(date, '$this->initialBookingDateFrom') AND pod.U_BookingDate <= CONVERT(date, '$this->initialBookingDateTo'))
                ORDER BY pod.U_BookingDate DESC, pricing.Code DESC
            "),
            'TotalInitialTruckers' => SAPAccessManager::getInstance()->getRows($this->queries['TotalInitialTruckers'] .
                "   WHERE pod.Code IS NOT NULL AND ( pod.U_BookingDate >= CONVERT(date, '$this->initialBookingDateFrom') AND pod.U_BookingDate <= CONVERT(date, '$this->initialBookingDateTo'))
                ORDER BY pod.U_BookingDate DESC, pod.Code DESC
            "),
            'SAPDateFormat' => SAPAccessManager::getInstance()->getRows($this->queries['SAPDateFormat'])[0]->DateFormat,
            'DateSeparator' => SAPAccessManager::getInstance()->getRows($this->queries['DateSeparator'])[0]->DateSep,
            'SAPPriceDecimal' => SAPAccessManager::getInstance()->getRows($this->queries['SAPPriceDecimal'])[0]->PriceDec,
            'CardCodes' => array_map(fn ($z) => $z->CardCode, SAPAccessManager::getInstance()->getRows($this->queries['CardCodes'])),
            'SAPClientBillingLogicExemption' => array_map(fn ($z) => $z->Code, SAPAccessManager::getInstance()->getRows($this->queries['SAPClientBillingLogicExemption'])),
        ];
        $this->apiData = [
            'CardCodeNames' => SAPAccessManager::getInstance()->getRows($this->queries['CardCodeNames']),
        ];
    }

    public function reFreshData(PctpWindowModel $model, string $prop)
    {
        switch ($prop) {
            case 'constants':
                if ((bool)$model->podTab->tableRows) { //cdc totalinittruck pod
                    $codes = join("','", array_map(fn ($z) => $z->Code, $model->podTab->tableRows));
                    $this->constants['CDC_DCD'] = SAPAccessManager::getInstance()->getRows(str_replace('TOP 10', '', $this->queries['CDC_DCD']) .
                        "   WHERE pod.U_BookingNumber IN ('$codes')
                        ORDER BY pod.U_BookingNumber
                    ");
                    $this->constants['TotalInitialTruckers'] = SAPAccessManager::getInstance()->getRows(str_replace('TOP 10', '', $this->queries['TotalInitialTruckers']) .
                        "   WHERE pod.U_BookingNumber IN ('$codes')
                        ORDER BY pod.U_BookingNumber
                    ");
                }
                if ((bool)$model->billingTab->tableRows) { //grouploc billing
                    $codes = join("','", array_map(fn ($z) => $z->Code, $model->billingTab->tableRows));
                    $this->constants['GroupLocation'] = SAPAccessManager::getInstance()->getRows(
                        str_replace('TOP 10', '', $this->queries['GroupLocation']) .
                            "   WHERE billing.Code IN ('$codes')
                        ORDER BY billing.Code
                    ",
                        new class implements IArrayProcessor
                        {
                            function process(array &$array)
                            {
                                foreach ($array as $object) {
                                    $object->GroupLocation = utf8_encode($object->GroupLocation);
                                }
                            }
                        }
                    );
                }
                if ((bool)$model->pricingTab->tableRows) { //taxtype pring
                    $codes = join("','", array_map(fn ($z) => $z->Code, $model->pricingTab->tableRows));
                    $where = " WHERE pricing.Code IN ('$codes') ";
                    if ((bool)$model->billingTab->tableRows) {
                        $codes = join("','", array_map(fn ($z) => $z->Code, $model->billingTab->tableRows));
                        $where .= " OR billing.Code IN ('$codes') ";
                    }
                    if ((bool)$model->tpTab->tableRows) {
                        $codes = join("','", array_map(fn ($z) => $z->Code, $model->tpTab->tableRows));
                        $where .= " OR tp.Code IN ('$codes') ";
                    }
                    $this->constants['TaxType'] = SAPAccessManager::getInstance()->getRows(str_replace('TOP 10', '', $this->queries['TaxType']) .
                        "   $where
                        ORDER BY pricing.Code
                    ");
                }
                $this->constants['SAPDateFormat'] = SAPAccessManager::getInstance()->getRows($this->queries['SAPDateFormat'])[0]->DateFormat;
                $this->constants['DateSeparator'] = SAPAccessManager::getInstance()->getRows($this->queries['DateSeparator'])[0]->DateSep;
                $this->constants['SAPPriceDecimal'] = SAPAccessManager::getInstance()->getRows($this->queries['SAPPriceDecimal'])[0]->PriceDec;
                $this->constants['CardCodes'] = array_map(fn ($z) => $z->CardCode, SAPAccessManager::getInstance()->getRows($this->queries['CardCodes']));
                break;
            case 'apiData':
                $this->apiData = [
                    'CardCodeNames' => SAPAccessManager::getInstance()->getRows($this->queries['CardCodeNames']),
                ];
                break;
            case 'sapDocumentStructures':
                $this->sapDocumentStructures = (object)[
                    SAPDocumentStructureType::SALES_ORDER->name() => new SalesOrderStructure(
                        SAPDocumentStructureType::SALES_ORDER,
                        [
                            'DocDate' => '',
                            'DocDueDate' => 'DeliveryDatePOD',
                            'CardCode' => 'SAPClient',
                            'DocType' => '',
                        ],
                        [
                            'ItemCode' => 'BookingId',
                            'Quantity' => '',
                            'PriceAfterVAT' => 'TotalRecClients',
                            // 'UnitPrice'=>'TotalRecClients',
                        ],
                        [
                            'DocDate' => date('Y-m-d'),
                            'Quantity' => 1,
                            'DocType' => 0,
                        ],
                        [
                            'DocDueDate' => ColumnType::DATE,
                            'PriceAfterVAT' => ColumnType::FLOAT,
                            // 'UnitPrice' => ColumnType::FLOAT,
                        ],
                        [
                            'PODSONum' => [
                                'enabled' => true,
                                'columnType' => 'ALPHANUMERIC',
                                'regex' => '^(\\s+)?$', // regex for empty
                                'failedMessage' => 'Sales Order is already created'
                            ],
                            'TotalRecClients' => [
                                'enabled' => true,
                                'columnType' => 'FLOAT',
                                'invalidValues' => ['', 0, null], // regex for empty
                                'failedMessage' => 'TotalRecClients does not have valid value'
                            ],
                        ],
                        [],
                        // [
                        //     'UnitPrice' => function(mixed $thisValue): float {
                        //         if (is_numeric($thisValue)) return floatval($thisValue)/1.12;
                        //         return 0;
                        //     }
                        // ],
                    ),
                    SAPDocumentStructureType::AR_INVOICE->name() => new ARInvoiceStructure(
                        SAPDocumentStructureType::AR_INVOICE,
                        [
                            'DocDate' => '',
                            'CardCode' => 'SAPClient',
                            'DocType' => '',
                        ],
                        [
                            'BaseEntry' => 'PODSONum',
                            'BaseLine' => '',
                            'BaseType' => '',
                            'Quantity' => '',
                            'WTLiable' => '',
                        ],
                        [
                            'DocDate' => date('Y-m-d'),
                            'BaseLine' => 0,
                            'BaseType' => 17,
                            'Quantity' => 1,
                            'DocType' => 0,
                            'WTLiable' => 0,
                        ],
                        [
                            'PriceAfterVAT' => ColumnType::FLOAT,
                        ],
                        [
                            'DocNum' => [
                                'enabled' => true,
                                'columnType' => 'ALPHANUMERIC',
                                'regex' => '^(\\s+)?$', // regex for empty
                                // 'failedMessage' => 'AR Invoice is already created',
                                'overrideFailedMessage' => 'Cannot create AR Invoice',
                                'overrideRegex' => '^(\\s+)?\\d+(\\s+)?$',
                                'overrideLine' => [
                                    'ItemCode' => 'BookingId',
                                    'Quantity' => '',
                                    'PriceAfterVAT' => 'RateAdjustments',
                                    'WTLiable' => '',
                                ],
                            ],
                            'PODSONum' => [
                                'enabled' => true,
                                'columnType' => 'ALPHANUMERIC',
                                'regex' => '\\d+', // regex for empty
                                'failedMessage' => 'Sales Order should be created first'
                            ],
                        ],
                        [
                            'sapField' => 'PriceAfterVAT',
                            'part' => 'lines',
                            'caption' => 'Choose rate:',
                            'options' => [
                                [
                                    'value' => 'ActualBilledRate',
                                    'text' => 'Actual Billed Amount Main Rates',
                                ],
                                [
                                    'value' => 'RateAdjustments',
                                    'text' => 'Rate Adjustments',
                                ],
                                [
                                    'value' => 'ActualDemurrage',
                                    'text' => 'Actual Demurrage',
                                ],
                                [
                                    'value' => 'ActualAddCharges',
                                    'text' => 'Actual Additional Charges',
                                ],
                            ],
                        ],
                    ),
                    SAPDocumentStructureType::AP_INVOICE->name() => new APInvoiceStructure(
                        SAPDocumentStructureType::AP_INVOICE,
                        [
                            'DocDate' => '',
                            'CardCode' => 'TruckerSAP',
                            'Comments' => 'Remarks',
                            'DocType' => '',
                        ],
                        [
                            'ItemCode' => 'BookingId',
                            'Quantity' => '',
                            'Price' => 'GrossTruckerRates',
                        ],
                        [
                            'DocDate' => date('Y-m-d'),
                            'Quantity' => 1,
                            'DocType' => 0,
                            'Comments' => '',
                        ],
                        [
                            'DocDate' => ColumnType::DATE,
                            'Price' => ColumnType::FLOAT,
                        ],
                        [
                            'DocNum' => [
                                'enabled' => true,
                                'columnType' => 'ALPHANUMERIC',
                                'regex' => '^(\\s+)?$', // regex for empty
                                // 'failedMessage' => 'AP Invoice is already created',
                                'overrideFailedMessage' => 'Cannot create AP Invoice',
                                'overrideRegex' => '^(\\s+)?\\d+(\\s+)?$',
                                'overrideLine' => [
                                    'ItemCode' => 'BookingId',
                                    'Quantity' => '',
                                    'Price' => 'GrossTruckerRates',
                                ],
                            ],
                            'GrossTruckerRates' => [
                                'enabled' => true,
                                'columnType' => 'FLOAT',
                                'invalidValues' => ['', 0, null], // regex for empty
                                'failedMessage' => 'GrossTruckerRates does not have valid value'
                            ],
                        ],
                        [
                            'sapField' => 'Price',
                            'part' => 'lines',
                            'caption' => 'Choose rate:',
                            'options' => [
                                [
                                    'value' => 'GrossTruckerRatesN',
                                    'text' => 'Gross Trucker Rates (Non-VAT)',
                                ],
                                [
                                    'value' => 'DemurrageN',
                                    'text' => 'Demurrage - Considering NON VAT Rate',
                                ],
                                [
                                    'value' => 'AddtlChargesN',
                                    'text' => 'Additional Charges Considering NON VAT Rate',
                                ],
                                [
                                    'value' => 'ActualRates',
                                    'text' => 'Actual rates charged by trucker',
                                ],
                                [
                                    'value' => 'RateAdjustments',
                                    'text' => 'Rate Adjustments',
                                ],
                                [
                                    'value' => 'ActualDemurrage',
                                    'text' => 'Actual Approved Demurrage',
                                ],
                                [
                                    'value' => 'ActualCharges',
                                    'text' => 'Actual Addtional Charges',
                                ],
                                [
                                    'value' => 'BoomTruck2',
                                    'text' => 'Boom Trucks',
                                ],
                                [
                                    'value' => 'OtherCharges',
                                    'text' => 'Other Charges',
                                ],
                                [
                                    'value' => 'TotalPenaltyWaived',
                                    'text' => 'Total Penalty Waived',
                                ],
                                [
                                    'value' => 'TotalPenalty',
                                    'text' => 'Total Penalty',
                                ],
                            ],
                        ],
                    ),
                ];
                break;
            default:
                # code...
                break;
        }
    }

    public function isImmutableFieldName(string $fieldName): bool
    {
        return (bool)array_filter($this->immutableFieldNames, fn ($z) => $z === $fieldName);
    }

    public function getUploadDirectory(): string
    {
        return $this->uploadDirectory;
    }

    public function getSQLColumnFormat(string $fieldName): string
    {
        return str_replace('?', $fieldName, $this->defaultSQLColumnPattern);
    }
}
