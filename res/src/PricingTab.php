<?php

require_once __DIR__ . '/../inc/restriction.php';

class PricingTab extends APctpWindowTab
{

    public function __construct(PctpWindowSettings $settings)
    {
        $this->script = file_get_contents(__DIR__ . '/../sql/pricing.sql');
        $this->extractScript = file_get_contents(__DIR__ . '/../sql/extract/pricing_extract_qry.sql');
        $this->preFetchRefreshScripts = [file_get_contents(__DIR__ . '/../sql/refresh_custom_tables/refresh_pricing_extract.sql')];
        $this->columnDefinitions = [
            new ColumnDefinition('PODNum', 'POD Document Number', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('BookingId', 'Booking ID', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('BookingDate', 'Booking Date', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('CustomerName', 'Client Name', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('ClientTag', 'Client Tag', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('ClientProject', 'Client Project', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('TruckerName', 'Trucker Name', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('TruckerTag', 'Trucker Tag', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('VehicleTypeCap', 'Vehicle Type & Capacity', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'vehicleTypeCapOptions'),
            new ColumnDefinition('DeliveryOrigin', 'Delivery Origin', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('ISLAND', 'ISLAND (ORIGIN)', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'islandsOptions'),
            new ColumnDefinition('Destination', 'Destination', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('ISLAND_D', 'ISLAND (DESTINATION)', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'islandsOptions'),
            new ColumnDefinition('IFINTERISLAND', 'if Interisland', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'yesNoOptions'),
            new ColumnDefinition('DeliveryStatus', 'DeliveryStatus', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'deliveryStatusOptions'),
            new ColumnDefinition('PODDocNum', 'Doc No. from DTR', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('TripType', 'Trip Type', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO, 'tripTypeOptions'),
            new ColumnDefinition('NoOfDrops', 'No Of Drops', ColumnType::INT, ColumnViewType::AUTO),
            new ColumnDefinition('RemarksDTR', 'Remarks', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('RemarksPOD', 'Remarks (POD)', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('GrossClientRates', 'Gross Client Rates', ColumnType::FLOAT),
            new ColumnDefinition('_GrossClientRatesTax', 'Gross Client Rates (Based on Tax Type)', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('RateBasis', 'Rate Basis (Client)', ColumnType::ALPHANUMERIC, ColumnViewType::DROPDOWN, 'rateBasisOptions'),
            new ColumnDefinition('TaxType', 'Tax Type', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('GrossTruckerRates', 'Gross Trucker', ColumnType::FLOAT),
            new ColumnDefinition('_GrossTruckerRatesTax', 'Gross Trucker Rates (based on TAX TYPE)', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('RateBasisT', 'Rate Basis (Trucker)', ColumnType::ALPHANUMERIC, ColumnViewType::DROPDOWN, 'rateBasisOptions'),
            new ColumnDefinition('TaxTypeT', 'Tax Type', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('_GrossProfitNet', 'Gross Profit', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('Demurrage', 'Demurrage (Client)', ColumnType::FLOAT),
            new ColumnDefinition('AddtlDrop', 'Additional Drop (Client)', ColumnType::FLOAT),
            new ColumnDefinition('BoomTruck', 'Boom Truck (Client)', ColumnType::FLOAT),
            new ColumnDefinition('Manpower', 'Manpower (Client)', ColumnType::FLOAT),
            new ColumnDefinition('Backload', 'Backload (Client)', ColumnType::FLOAT),
            new ColumnDefinition('_TotalAddtlCharges', 'Total Additional Charges', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('_Demurrage4', 'Demurrage Client (Base on Tax Type)', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('_AddtlCharges2', 'Additional Charges Client (Base on Tax Type)', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('Demurrage2', 'Demurrage (Trucker)', ColumnType::FLOAT),
            new ColumnDefinition('AddtlDrop2', 'Additional Drop (Trucker)', ColumnType::FLOAT),
            new ColumnDefinition('BoomTruck2', 'Boom Truck (Trucker)', ColumnType::FLOAT),
            new ColumnDefinition('Manpower2', 'Manpower (Trucker)', ColumnType::FLOAT),
            new ColumnDefinition('Backload2', 'Backload (Trucker)', ColumnType::FLOAT),
            new ColumnDefinition('_totalAddtlCharges2', 'Total Additional Charges', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('_Demurrage3', 'Demurrage  (Base on Tax Type)', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('_AddtlCharges', 'Additional Charges (Base on Tax Type)', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('_GrossProfit', 'Gross profit (Other charges)', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('_TotalInitialClient', 'Total Client Rate', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('_TotalInitialTruckers', 'Total Trucker Cost', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('_TotalGrossProfit', 'Total Gross Profit', ColumnType::FLOAT, ColumnViewType::AUTO),
            // from billing
            new ColumnDefinition('PODSONum', 'Sales Order No.', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('DocNum', 'AR invoice', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('ActualBilledRate', 'Actual Billed Amount Main Rates', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('BillingRateAdjustments', 'Rate Adjustments', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('BillingActualDemurrage', 'Actual Demurrage', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('ActualAddCharges', 'Actual Additional Charges', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('TotalRecClients', 'Total Receivable from Clients, per SI Recon with BR', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('TotalAR', 'Total AR (Stand Alone)', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('VarAR', 'Variance', ColumnType::FLOAT, ColumnViewType::AUTO),
            // from tp
            new ColumnDefinition('PVNo', 'Payment Voucher Number', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('APDocNum', 'AP Invoice', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('Paid', 'Paid AP Invoice', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('ActualRates', 'Actual rates charged by trucker', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('TPRateAdjustments', 'Rate Adjustments', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('TPActualDemurrage', 'Actual Approved Demurrage', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('ActualCharges', 'Actual Addtional Charges', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('TPBoomTruck2', 'Boom Truck', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('OtherCharges', 'Other Charges', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('TotalPayable', 'Total Payable to Truckers', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('TotalAP', 'Total AP (Stand Alone)', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('VarTP', 'Variance', ColumnType::FLOAT, ColumnViewType::AUTO),
        ];

        $this->relatedTables = [
            new RelatedTable('billingTab', 'BookingId', 'BookingId'),
            new RelatedTable('tpTab', 'BookingId', 'BookingId'),
        ];
        $this->fieldsFindOptions = [
            'PODSONum' => [
                'alias' => 'billing',
                'field' => 'PODSONum',
                'involveInFindText' => true,
            ],
            // 'ClientTag' => [
            //     'alias' => 'pod',
            //     'field' => 'SAPClient',
            // ],
            // 'TruckerTag' => [
            //     'alias' => 'pod',
            //     'field' => 'SAPTrucker',
            // ],
            'BookingDate' => [
                'alias' => 'pod',
                'field' => 'BookingDate',
                'needColumnFormat' => true,
                'involveInFindText' => true,
            ],
        ];
        $this->foreignFields = [
            'ISLAND',
            'IFINTERISLAND',
            'ISLAND_D',
            'PODSONum',
            'DocNum',
            'ActualBilledRate',
            'BillingRateAdjustments',
            'BillingActualDemurrage',
            'ActualAddCharges',
            'TotalRecClients',
            'TotalAR',
            'VarAR',
            'PVNo',
            'APDocNum',
            'Paid',
            'ActualRates',
            'TPRateAdjustments',
            'TPActualDemurrage',
            'ActualCharges',
            'TPBoomTruck2',
            'OtherCharges',
            'TotalPayable',
            'TotalAP',
            'VarTP',
            'PODDocNum',
        ];
        $this->searchableFields = [
            'PODDocNum',
        ];
        $this->disableSomeFields = [
            'DisableFieldsForBilling' => [
                'GrossClientRates',
                'RateBasis',
                'Demurrage',
                'AddtlDrop',
                'BoomTruck',
                'Manpower',
                'Backload'
            ],
            'DisableFieldsForTp' => [
                'GrossTruckerRates',
                'RateBasisT',
                'Demurrage2',
                'AddtlDrop2',
                'BoomTruck2',
                'Manpower2',
                'Backload2'
            ]
        ];
        parent::__construct(
            'Code',
            $settings->tabTables[lcfirst(get_class($this))],
            $settings
        );

        $this->columnValidations = [
            /////////////////////////////////////////////////BILLING
            'GrossClientRates' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTab',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'billing',
                                            'foreignField' => 'PODNum',
                                            'field' => 'GrossInitialRate',
                                            'value' => 'self',
                                            'bool' => true
                                        ]
                                    ]
                                ]
                            ],
                            'relatedUpdates' => [
                                [
                                    'tab' => 'billing',
                                    'fields' => [
                                        'GrossInitialRate' => 'self',
                                    ]
                                ]
                            ]
                        ],
                    ]
                ]
            ],
            'Demurrage' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTab',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'billing',
                                            'foreignField' => 'PODNum',
                                            'field' => 'Demurrage',
                                            'value' => 'self',
                                            'bool' => true
                                        ]
                                    ]
                                ]
                            ],
                            'relatedUpdates' => [
                                [
                                    'tab' => 'billing',
                                    'fields' => [
                                        'Demurrage' => 'self',
                                    ]
                                ]
                            ]
                        ],
                    ]
                ]
            ],
            ////////////////////////////////////////////////////////////////////////TP
            '_TotalAddtlCharges' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTab',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'billing',
                                            'foreignField' => 'PODNum',
                                            'field' => 'AddCharges',
                                            'value' => 'self',
                                            'bool' => true
                                        ]
                                    ]
                                ]
                            ],
                            'relatedUpdates' => [
                                [
                                    'tab' => 'billing',
                                    'fields' => [
                                        'AddCharges' => 'self',
                                    ]
                                ]
                            ]
                        ],
                    ]
                ]
            ],
            'AddtlDrop' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeOtherFieldByFormula',
                                        'arg' => (object)[
                                            'field' => '_TotalAddtlCharges',
                                            'formula' => '_TotalAddtlCharges',
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'billing',
                                            'foreignField' => 'PODNum',
                                            'field' => 'AddCharges',
                                            'formula' => '_TotalAddtlCharges',
                                            'bool' => true,
                                            'useFormulaInsideRow' => true
                                        ]
                                    ]
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'BoomTruck' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeOtherFieldByFormula',
                                        'arg' => (object)[
                                            'field' => '_TotalAddtlCharges',
                                            'formula' => '_TotalAddtlCharges',
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'billing',
                                            'foreignField' => 'PODNum',
                                            'field' => 'AddCharges',
                                            'formula' => '_TotalAddtlCharges',
                                            'bool' => true,
                                            'useFormulaInsideRow' => true
                                        ]
                                    ]
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'Manpower' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeOtherFieldByFormula',
                                        'arg' => (object)[
                                            'field' => '_TotalAddtlCharges',
                                            'formula' => '_TotalAddtlCharges',
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'billing',
                                            'foreignField' => 'PODNum',
                                            'field' => 'AddCharges',
                                            'formula' => '_TotalAddtlCharges',
                                            'bool' => true,
                                            'useFormulaInsideRow' => true
                                        ]
                                    ]
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'Backload' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeOtherFieldByFormula',
                                        'arg' => (object)[
                                            'field' => '_TotalAddtlCharges',
                                            'formula' => '_TotalAddtlCharges',
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'billing',
                                            'foreignField' => 'PODNum',
                                            'field' => 'AddCharges',
                                            'formula' => '_TotalAddtlCharges',
                                            'bool' => true,
                                            'useFormulaInsideRow' => true
                                        ]
                                    ]
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'GrossTruckerRates' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTab',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'GrossTruckerRates',
                                            'value' => 'self',
                                            'bool' => true
                                        ]
                                    ]
                                ]
                            ],
                            'relatedUpdates' => [
                                [
                                    'tab' => 'tp',
                                    'fields' => [
                                        'GrossTruckerRates' => 'self',
                                    ]
                                ]
                            ]
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'GrossTruckerRatesN',
                                            'formula' => '_GrossTruckerRatesTax',
                                            'bool' => true
                                        ]
                                    ]
                                ]
                            ],
                            'relatedUpdates' => [
                                [
                                    'tab' => 'tp',
                                    'fields' => [
                                        'GrossTruckerRatesN' => 'self',
                                    ]
                                ]
                            ]
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'pod',
                                            'foreignField' => 'Code',
                                            'field' => '_LostPenaltyCalc',
                                            'formula' => '_LostPenaltyCalc',
                                            'bool' => true,
                                            'updateConstantName' => 'TotalInitialTruckers',
                                            'refField' => 'PODNum',
                                            'fieldName' => 'TotalInitialTruckers',
                                            'fieldFormula' => '_TotalInitialTruckers'
                                        ]
                                    ]
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'RateBasisT' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTab',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'RateBasis',
                                            'value' => 'self',
                                            'bool' => true
                                        ]
                                    ]
                                ]
                            ],
                            'relatedUpdates' => [
                                [
                                    'tab' => 'tp',
                                    'fields' => [
                                        'RateBasis' => 'self',
                                    ]
                                ]
                            ]
                        ],
                    ]
                ]
            ],
            'Demurrage2' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTab',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'Demurrage',
                                            'value' => 'self',
                                            'bool' => true
                                        ]
                                    ]
                                ]
                            ],
                            'relatedUpdates' => [
                                [
                                    'tab' => 'tp',
                                    'fields' => [
                                        'Demurrage' => 'self',
                                    ]
                                ]
                            ]
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'DemurrageN',
                                            'formula' => '_Demurrage3',
                                            'bool' => true,
                                            'useFormulaInsideRow' => true
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'pod',
                                            'foreignField' => 'Code',
                                            'field' => '_LostPenaltyCalc',
                                            'formula' => '_LostPenaltyCalc',
                                            'bool' => true,
                                            'updateConstantName' => 'TotalInitialTruckers',
                                            'refField' => 'PODNum',
                                            'fieldName' => 'TotalInitialTruckers',
                                            'fieldFormula' => '_TotalInitialTruckers'
                                        ]
                                    ]
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'AddtlDrop2' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTab',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'AddtlDrop',
                                            'value' => 'self',
                                            'bool' => true
                                        ]
                                    ]
                                ]
                            ],
                            'relatedUpdates' => [
                                [
                                    'tab' => 'tp',
                                    'fields' => [
                                        'AddtlDrop' => 'self',
                                    ]
                                ]
                            ]
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeOtherFieldByFormula',
                                        'arg' => (object)[
                                            'field' => '_totalAddtlCharges2',
                                            'formula' => '_totalAddtlCharges2',
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeOtherFieldByFormula',
                                        'arg' => (object)[
                                            'field' => '_AddtlCharges',
                                            'formula' => '_AddtlCharges',
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'Addtlcharges',
                                            'formula' => '_totalAddtlCharges2',
                                            'bool' => true,
                                            'useFormulaInsideRow' => true
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'AddtlChargesN',
                                            'formula' => '_AddtlCharges',
                                            'bool' => true,
                                            'useFormulaInsideRow' => true
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'pod',
                                            'foreignField' => 'Code',
                                            'field' => '_LostPenaltyCalc',
                                            'formula' => '_LostPenaltyCalc',
                                            'bool' => true,
                                            'updateConstantName' => 'TotalInitialTruckers',
                                            'refField' => 'PODNum',
                                            'fieldName' => 'TotalInitialTruckers',
                                            'fieldFormula' => '_TotalInitialTruckers'
                                        ]
                                    ]
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'BoomTruck2' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTab',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'BoomTruck',
                                            'value' => 'self',
                                            'bool' => true
                                        ]
                                    ]
                                ]
                            ],
                            'relatedUpdates' => [
                                [
                                    'tab' => 'tp',
                                    'fields' => [
                                        'BoomTruck' => 'self',
                                    ]
                                ]
                            ]
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeOtherFieldByFormula',
                                        'arg' => (object)[
                                            'field' => '_totalAddtlCharges2',
                                            'formula' => '_totalAddtlCharges2',
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeOtherFieldByFormula',
                                        'arg' => (object)[
                                            'field' => '_AddtlCharges',
                                            'formula' => '_AddtlCharges',
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'Addtlcharges',
                                            'formula' => '_totalAddtlCharges2',
                                            'bool' => true,
                                            'useFormulaInsideRow' => true
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'AddtlChargesN',
                                            'formula' => '_AddtlCharges',
                                            'bool' => true,
                                            'useFormulaInsideRow' => true
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'pod',
                                            'foreignField' => 'Code',
                                            'field' => '_LostPenaltyCalc',
                                            'formula' => '_LostPenaltyCalc',
                                            'bool' => true,
                                            'updateConstantName' => 'TotalInitialTruckers',
                                            'refField' => 'PODNum',
                                            'fieldName' => 'TotalInitialTruckers',
                                            'fieldFormula' => '_TotalInitialTruckers'
                                        ]
                                    ]
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'Manpower2' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTab',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'Manpower',
                                            'value' => 'self',
                                            'bool' => true
                                        ]
                                    ]
                                ]
                            ],
                            'relatedUpdates' => [
                                [
                                    'tab' => 'tp',
                                    'fields' => [
                                        'Manpower' => 'self',
                                    ]
                                ]
                            ]
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeOtherFieldByFormula',
                                        'arg' => (object)[
                                            'field' => '_totalAddtlCharges2',
                                            'formula' => '_totalAddtlCharges2',
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeOtherFieldByFormula',
                                        'arg' => (object)[
                                            'field' => '_AddtlCharges',
                                            'formula' => '_AddtlCharges',
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'Addtlcharges',
                                            'formula' => '_totalAddtlCharges2',
                                            'bool' => true,
                                            'useFormulaInsideRow' => true
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'AddtlChargesN',
                                            'formula' => '_AddtlCharges',
                                            'bool' => true,
                                            'useFormulaInsideRow' => true
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'pod',
                                            'foreignField' => 'Code',
                                            'field' => '_LostPenaltyCalc',
                                            'formula' => '_LostPenaltyCalc',
                                            'bool' => true,
                                            'updateConstantName' => 'TotalInitialTruckers',
                                            'refField' => 'PODNum',
                                            'fieldName' => 'TotalInitialTruckers',
                                            'fieldFormula' => '_TotalInitialTruckers'
                                        ]
                                    ]
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'Backload2' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTab',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'BackLoad',
                                            'value' => 'self',
                                            'bool' => true
                                        ]
                                    ]
                                ]
                            ],
                            'relatedUpdates' => [
                                [
                                    'tab' => 'tp',
                                    'fields' => [
                                        'BackLoad' => 'self',
                                    ]
                                ]
                            ]
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeOtherFieldByFormula',
                                        'arg' => (object)[
                                            'field' => '_totalAddtlCharges2',
                                            'formula' => '_totalAddtlCharges2',
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeOtherFieldByFormula',
                                        'arg' => (object)[
                                            'field' => '_AddtlCharges',
                                            'formula' => '_AddtlCharges',
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'Addtlcharges',
                                            'formula' => '_totalAddtlCharges2',
                                            'bool' => true,
                                            'useFormulaInsideRow' => true
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'AddtlChargesN',
                                            'formula' => '_AddtlCharges',
                                            'bool' => true,
                                            'useFormulaInsideRow' => true
                                        ]
                                    ]
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTabByFormula',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'pod',
                                            'foreignField' => 'Code',
                                            'field' => '_LostPenaltyCalc',
                                            'formula' => '_LostPenaltyCalc',
                                            'bool' => true,
                                            'updateConstantName' => 'TotalInitialTruckers',
                                            'refField' => 'PODNum',
                                            'fieldName' => 'TotalInitialTruckers',
                                            'fieldFormula' => '_TotalInitialTruckers'
                                        ]
                                    ]
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            '_totalAddtlCharges2' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTab',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'Addtlcharges',
                                            'value' => 'self',
                                            'bool' => true
                                        ]
                                    ]
                                ]
                            ],
                            'relatedUpdates' => [
                                [
                                    'tab' => 'tp',
                                    'fields' => [
                                        'Addtlcharges' => 'self',
                                    ]
                                ]
                            ]
                        ],
                    ]
                ]
            ],
            '_Demurrage3' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'changeFieldValueFromOtherTab',
                                        'arg' => (object)[
                                            'tab' => 'pricing',
                                            'refField' => 'PODNum',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'DemurrageN',
                                            'value' => 'self',
                                            'bool' => true
                                        ]
                                    ]
                                ]
                            ],
                            'relatedUpdates' => [
                                [
                                    'tab' => 'tp',
                                    'fields' => [
                                        'DemurrageN' => 'self',
                                    ]
                                ]
                            ]
                        ],
                    ]
                ]
            ],
            'RateBasis' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [''],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => [
                                        'callback' => 'clearOtherElementValue',
                                        'arg' => (object)[
                                            'targetField' => 'GrossClientRates',
                                        ],
                                    ],
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'RateBasisT' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [''],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => [
                                        'callback' => 'clearOtherElementValue',
                                        'arg' => (object)[
                                            'targetField' => 'GrossTruckerRates',
                                        ],
                                    ],
                                ]
                            ],
                        ],
                    ]
                ]
            ],
        ];
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
