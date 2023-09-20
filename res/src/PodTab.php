<?php

require_once __DIR__ . '/../inc/restriction.php';

class PodTab extends APctpWindowTab
{
    public function __construct(PctpWindowSettings $settings)
    {
        $this->script = file_get_contents(__DIR__ . '/../sql/pod.sql');
        $newTag = isset($settings->config['enable_unified_table']) && $settings->config['enable_unified_table'] ? '_new' : '';
        $this->extractScript = file_get_contents(__DIR__ . '/../sql/extract/pod_extract_qry'.$newTag.'.sql');
        $this->preFetchRefreshScripts = [
            file_get_contents(__DIR__ . '/../sql/refresh_custom_tables/refresh_pod_extract.sql'),
        ];
        $this->columnDefinitions = [
            new ColumnDefinition('Attachment', 'Attachment', ColumnType::TEXT),
            new ColumnDefinition('Code', 'POD Number', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('BookingDate', 'Booking Date', ColumnType::DATE),
            new ColumnDefinition('BookingNumber', 'Booking Number', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('PODSONum', 'SAP ID (Sales Order)', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('ClientName', 'Client Name', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('GroupProject', 'Group Project / Location (SAP)', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('SAPClient', 'SAP Client', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('TruckerName', 'Trucker Name', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('SAPTrucker', 'SAP Trucker Code', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('PlateNumber', 'Plate Number', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('VehicleTypeCap', 'Vehicle Type & Capacity', ColumnType::ALPHANUMERIC, ColumnViewType::DROPDOWN, 'vehicleTypeCapOptions'),
            new ColumnDefinition('DeliveryOrigin', 'Delivery Origin', ColumnType::TEXT),
            new ColumnDefinition('ISLAND', 'ISLAND (ORIGIN)', ColumnType::ALPHANUMERIC, ColumnViewType::DROPDOWN, 'islandsOptions'),
            new ColumnDefinition('Destination', 'Destination', ColumnType::TEXT),
            new ColumnDefinition('ISLAND_D', 'ISLAND (DESTINATION)', ColumnType::ALPHANUMERIC, ColumnViewType::DROPDOWN, 'islandsOptions'),
            new ColumnDefinition('IFINTERISLAND', 'if Interisland', ColumnType::ALPHANUMERIC, ColumnViewType::DROPDOWN, 'yesNoOptions'),
            new ColumnDefinition('DeliveryStatus', 'Delivery Status', ColumnType::ALPHANUMERIC, ColumnViewType::DROPDOWN, 'deliveryStatusOptions'),
            new ColumnDefinition('DeliveryDateDTR', 'Delivery Completion Date (PER DTR)', ColumnType::DATE),
            new ColumnDefinition('DeliveryDatePOD', 'Delivery Complete Date (PER POD)', ColumnType::DATE),
            new ColumnDefinition('NoOfDrops', 'No of Drops', ColumnType::INT),
            new ColumnDefinition('TripType', 'Trip Type', ColumnType::ALPHANUMERIC, ColumnViewType::DROPDOWN, 'tripTypeOptions'),
            new ColumnDefinition('Remarks', 'Remarks', ColumnType::TEXT),
            new ColumnDefinition('DocNum', 'Document Number', ColumnType::TEXT),
            new ColumnDefinition('TripTicketNo', 'Trip Ticket #', ColumnType::TEXT),
            new ColumnDefinition('WaybillNo', 'Waybill #', ColumnType::TEXT),
            new ColumnDefinition('ShipmentNo', 'Shipment #', ColumnType::TEXT),
            new ColumnDefinition('DeliveryReceiptNo', 'Delivery Receipt #', ColumnType::TEXT),
            new ColumnDefinition('SeriesNo', 'Series #', ColumnType::TEXT),
            new ColumnDefinition('OtherPODDoc', 'Other POD Document', ColumnType::TEXT),
            new ColumnDefinition('RemarksPOD', 'Remarks (POD)', ColumnType::TEXT),
            new ColumnDefinition('Receivedby', 'Received by', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('ClientReceivedDate', 'Client Received Date', ColumnType::DATE),
            new ColumnDefinition('ActualDateRec_Intitial', 'Actual date received Soft copy (Initial)', ColumnType::DATE),
            new ColumnDefinition('InitialHCRecDate', 'Initial HC Inteluck Received Date', ColumnType::DATE),
            new ColumnDefinition('ActualHCRecDate', 'Actual HC Inteluck Received Date', ColumnType::DATE),
            new ColumnDefinition('DateReturned', 'Date Returned', ColumnType::DATE),
            new ColumnDefinition('PODinCharge', 'POD in Charge', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('VerifiedDateHC', 'Verified Date Hard Copy GOOD', ColumnType::DATE),
            new ColumnDefinition('PODStatusDetail', 'POD Status (Detail)', ColumnType::TEXT, ColumnViewType::DROPDOWN, 'podStatusOptions', true),
            new ColumnDefinition('PTFNo', 'PTF (POD Transmitall Form) #', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('DateForwardedBT', 'Date Forwarded to BT (Hard Copy)', ColumnType::DATE),
            new ColumnDefinition('_VERIFICATION_TAT', 'Verification Turnaround time (TAT)', ColumnType::INT, ColumnViewType::AUTO),
            new ColumnDefinition('_POD_TAT', 'POD Turnaround time (TAT)', ColumnType::INT, ColumnViewType::AUTO),
            new ColumnDefinition('BillingDeadline', 'Billing Deadline', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('BillingStatus', 'Billing Status', ColumnType::ALPHANUMERIC, ColumnViewType::DROPDOWN, 'billingStatusOptions', true,
                ["PendingforClient'sApproval", "SenttoBT"]
            ),
            new ColumnDefinition('ServiceType', 'Service Type', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('SINo', 'SI #', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('BillingTeam', 'Billing Team in Charge', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('BTRemarks', 'BT Remarks', ColumnType::TEXT, ColumnViewType::AUTO),
            new ColumnDefinition('SOBNumber', 'SOB Number', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('OutletNo', 'Outlet No. (Criteria for GetCocaRates)', ColumnType::TEXT),
            new ColumnDefinition('CBM', 'CBM (Cubic meter) - Based on SI/DR', ColumnType::TEXT),
            new ColumnDefinition('SI_DRNo', 'Sales Invoice No/ Delivery Receipt No', ColumnType::TEXT),
            new ColumnDefinition('DeliveryMode', 'Delivery Mode', ColumnType::TEXT),
            new ColumnDefinition('SourceWhse', 'Source Whse - Based on DTT Stamp', ColumnType::TEXT),
            new ColumnDefinition('DestinationClient', 'Destination - Client\'s Customer', ColumnType::TEXT),
            new ColumnDefinition('TotalInvAmount', 'Total Invoice Amount', ColumnType::TEXT),
            new ColumnDefinition('SONo', 'SO No - Listed on Delivery Receipt', ColumnType::TEXT),
            new ColumnDefinition('NameCustomer', 'Name of Customer', ColumnType::TEXT),
            new ColumnDefinition('CategoryDR', 'Category - Listed on Delivery Receipt', ColumnType::TEXT),
            new ColumnDefinition('ForwardLoad', 'Forward Load', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('BackLoad', 'Back Load', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('IDNumber', 'ID Number', ColumnType::TEXT),
            new ColumnDefinition('TypeOfAccessorial', 'Type of Accessorial', ColumnType::ALPHANUMERIC, ColumnViewType::DROPDOWN, 'typeOfAccessorialOptions'),
            new ColumnDefinition('ApprovalStatus', 'Approval Status of Accessorial', ColumnType::TEXT),
            new ColumnDefinition('TimeInEmptyDem', 'Time In (Empty Demurrage)', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('TimeOutEmptyDem', 'Time Out (Empty Demurrage)', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('VerifiedEmptyDem', 'Verified Empty Demurrage', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('TimeInLoadedDem', 'Time In (Loaded Demurrage)', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('TimeOutLoadedDem', 'Time Out (Loaded Demurrage)', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('VerifiedLoadedDem', 'Verified Loaded Demurrage', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('Remarks2', 'Remarks', ColumnType::TEXT),
            new ColumnDefinition('TimeInAdvLoading', 'Time In (Advance Loading)', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('DayOfTheWeek', 'Day Of The Week', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('TimeIn', 'Time In', ColumnType::TIME),
            new ColumnDefinition('TimeOut', 'TimeOut', ColumnType::TIME),
            new ColumnDefinition('TotalNoExceed', 'Total No. Exceed', ColumnType::INT, ColumnViewType::AUTO),
            new ColumnDefinition('ODOIn', 'ODO In', ColumnType::INT),
            new ColumnDefinition('ODOOut', 'ODO Out', ColumnType::INT),
            new ColumnDefinition('TotalUsage', 'Total Usage', ColumnType::INT, ColumnViewType::AUTO),
            new ColumnDefinition('_ClientSubStatus', 'Client Submission Status', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('_ClientSubOverdue', 'Client Sub Overdue Days', ColumnType::INT, ColumnViewType::AUTO),
            new ColumnDefinition('_ClientPenaltyCalc', 'Client Penalty Calculation', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('_PODStatusPayment', 'POD Status for Payment Processing', ColumnType::ALPHANUMERIC, ColumnViewType::AUTO),
            new ColumnDefinition('_PODSubmitDeadline', 'POD Submit Deadline', ColumnType::DATE, ColumnViewType::AUTO),
            new ColumnDefinition('_OverdueDays', 'Overdue Days', ColumnType::INT, ColumnViewType::AUTO),
            new ColumnDefinition('_InteluckPenaltyCalc', 'Inteluck - Penalty Calculation', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('WaivedDays', 'CRD Waived Days', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('HolidayOrWeekend', 'IRD Waived Days', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('_LostPenaltyCalc', 'Lost - Penalty Calculation', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('PenaltiesManual', 'Penalties', ColumnType::FLOAT),
            new ColumnDefinition('_TotalSubPenalties', 'Total Submission Penalties', ColumnType::FLOAT, ColumnViewType::AUTO),
            new ColumnDefinition('Waived', 'Waived?', ColumnType::ALPHANUMERIC, ColumnViewType::DROPDOWN, 'yesNoOptions'),
            new ColumnDefinition('PercPenaltyCharge', '% Penalty Charged', ColumnType::FLOAT),
            new ColumnDefinition('Approvedby', 'Approved by', ColumnType::ALPHANUMERIC),
            new ColumnDefinition('_TotalPenaltyWaived', 'Total Penalty Waived', ColumnType::FLOAT, ColumnViewType::AUTO),
        ];
        $this->unifiedAliasColumns = $newTag === '' ? [] : [
            'DisableTableRow' => 'po_DisableTableRow',
            ' Code ' => ' po_Code ',
            'U_BackLoad ' => 'po_U_BackLoad ',
            'U_DocNum ' => 'po_U_DocNum ',
        ];
        $this->sqlStringColumns = ['WaybillNo'];
        $this->foreignFields = ['GroupProject', 'ARDocNum', 'PODSONum'];
        $this->columnsNeedUtf8Conversion = ['DeliveryOrigin'];
        $this->relatedTables = [
            new RelatedTable('billingTab', 'BookingNumber', 'BookingId'),
            new RelatedTable('tpTab', 'BookingNumber', 'BookingId'),
            new RelatedTable('pricingTab', 'BookingNumber', 'BookingId'),
        ];
        $this->excludeFromWildCardSearch = [
            'BillingStatus',
            'PODSONum'
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
        ];
        $this->fieldDatesToFormat = ['PODSubmitDeadline', 'BillingDeadline'];
        $this->notSameColumns = [
            'BillingTab' => [
                'DocNum',
            ],
            'TpTab' => [
                'DocNum',
            ],
        ];
        $this->searchableFields = [
            'DocNum',
            'TripTicketNo',
            'WaybillNo',
            'ShipmentNo',
            'DeliveryReceiptNo',
            'SeriesNo',
            'OtherPODDoc',
            'PODSONum'
        ];
        parent::__construct(
            'Code',
            $settings->tabTables[lcfirst(get_class($this))],
            $settings
        );
        $this->updateFieldAlias = [
            'Code' => 'BookingNumber'
        ];
        $this->fieldEnumValues = (object)['fields' => ['SAPClient', 'SAPTrucker'], 'enum' => 'CardCodes'];
        $this->optionalFields = ['TripType'];
        //key value pair -- FieldColumn as Key and validation options as value
        $this->columnValidations = [
            'PODStatusDetail' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => ['Verified'],
                            'for' => ['', 'update', 'initialize'],
                            'observee' => (object)[
                                'fields' => (function ($columns): array {
                                    $observees = [];
                                    foreach ($columns as $column) {
                                        if ($column->fieldName === 'PODStatusDetail') {
                                            $observees[] = 'BillingStatus';
                                            return $observees;
                                        } else if (
                                            !$this->settings->isImmutableFieldName($column->fieldName)
                                            && !in_array(
                                                $column->fieldName,
                                                [
                                                    'PODSONum',
                                                    'DocNum',
                                                    'PODinCharge',
                                                    'ARDocNum',
                                                    'Remarks',
                                                    '_VERIFICATION_TAT',
                                                    '_POD_TAT'
                                                ]
                                            )
                                            && !in_array($column->fieldName, $this->optionalFields)
                                        ) {
                                            $observees[] = $column->fieldName;
                                        }
                                    }
                                    return [];
                                })($this->columnDefinitions),
                                'acceptedValuesRegex' => '',
                                'invalidValues' => (object)[
                                    'default' => [null, '', 0],
                                    'BillingStatus' => [
                                        'values' => ['Cancelled'],
                                        'message' => 'BillingStatus is cancelled, this cannot be verified'
                                    ],
                                    'WaybillNo' => [
                                        'passedValues' => [0],
                                    ],
                                ],
                                'result' => (object)[
                                    'evaluations' => [
                                        (object)[
                                            'callback' => 'isDate1EarlierThanDate2',
                                            'arg' => (object)[
                                                'dateField1' => 'DeliveryDateDTR',
                                                'dateField2' => 'BookingDate',
                                            ],
                                            'failedMessage' => 'DeliveryDateDTR should not be earlier than BookingDate',
                                            'failedMethod' => 'clearElementValue'
                                        ],
                                        (object)[
                                            'callback' => 'isDate1EarlierThanDate2',
                                            'arg' => (object)[
                                                'dateField1' => 'DeliveryDatePOD',
                                                'dateField2' => 'BookingDate',
                                            ],
                                            'failedMessage' => 'DeliveryDatePOD should not be earlier than BookingDate',
                                            'failedMethod' => 'clearElementValue'
                                        ],
                                    ],
                                    'success' => (object)[
                                        'callback' => 'disableFields',
                                        'arg' => (object)[
                                            'fieldNames' => (function ($columns): array {
                                                $observees = [];
                                                foreach ($columns as $column) {
                                                    if (
                                                        !$this->settings->isImmutableFieldName($column->fieldName)
                                                        && !in_array($column->fieldName, [
                                                            'PODSONum',
                                                            'PODinCharge',
                                                            'PODStatusDetail',
                                                            'WaivedDays',
                                                            'HolidayOrWeekend',
                                                            'Waived',
                                                            'PercPenaltyCharge',
                                                            'Approvedby',
                                                            'DateForwardedBT',
                                                            'BillingStatus',
                                                            'PenaltiesManual'
                                                        ])
                                                    ) {
                                                        $observees[] = $column->fieldName;
                                                    }
                                                }
                                                return $observees;
                                            })($this->columnDefinitions)
                                        ],
                                        'proceedFieldOnchange' => false
                                    ],
                                    'failed' => (object)[
                                        'for' => [
                                            'default' => [
                                                'callback' => 'clearElementValue',
                                            ]
                                        ]
                                    ]
                                ]
                            ]
                        ],
                        (object)[
                            'values' => ['OngoingVerification'],
                            'for' => ['', 'update', 'initialize'],
                            'observee' => (object)[
                                'fields' => ['ClientReceivedDate', 'InitialHCRecDate'],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [null, '', 0],
                                'result' => (object)[
                                    'evaluations' => [
                                        (object)[
                                            'callback' => 'isDate1EarlierThanDate2',
                                            'arg' => (object)[
                                                'dateField1' => 'InitialHCRecDate',
                                                'dateField2' => 'DeliveryDateDTR',
                                            ],
                                            'failedMessage' => 'InitialHCRecDate should not be earlier than DeliveryDateDTR',
                                            'failedMethod' => 'clearElementValue'
                                        ],
                                        (object)[
                                            'callback' => 'isDate1EarlierThanDate2',
                                            'arg' => (object)[
                                                'dateField1' => 'ActualHCRecDate',
                                                'dateField2' => 'DeliveryDateDTR',
                                            ],
                                            'failedMessage' => 'ActualHCRecDate should not be earlier than DeliveryDateDTR',
                                            'failedMethod' => 'clearElementValue'
                                        ],
                                        (object)[
                                            'callback' => 'isDate1EarlierThanDate2',
                                            'arg' => (object)[
                                                'dateField1' => 'DateReturned',
                                                'dateField2' => 'DeliveryDatePOD',
                                            ],
                                            'failedMessage' => 'DateReturned should not be earlier than DeliveryDatePOD',
                                            'failedMethod' => 'clearElementValue'
                                        ],
                                        (object)[
                                            'callback' => 'isDate1EarlierThanDate2',
                                            'arg' => (object)[
                                                'dateField1' => 'VerifiedDateHC',
                                                'dateField2' => 'DeliveryDatePOD',
                                            ],
                                            'failedMessage' => 'VerifiedDateHC should not be earlier than DeliveryDatePOD',
                                            'failedMethod' => 'clearElementValue'
                                        ],
                                    ],
                                    'failed' => (object)[
                                        'message' => "Fields 'ClientReceivedDate', 'InitialHCRecDate' should have a valid value",
                                        'callback' => 'clearElementValue'
                                    ]
                                ]
                            ]
                        ],
                        (object)[
                            'values' => ['OngoingVerification', 'OnholdbyPOD'],
                            'for' => ['', 'update', 'initialize'],
                            'observee' => (object)[
                                'fields' => ['ClientReceivedDate', 'InitialHCRecDate'],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [null, '', 0],
                                'result' => (object)[
                                    'failed' => (object)[
                                        'message' => "Fields 'ClientReceivedDate', 'InitialHCRecDate' should have a valid value",
                                        'callback' => 'clearElementValue'
                                    ]
                                ]
                            ]
                        ],
                        (object)[
                            'values' => ['Returnedtotrucker'],
                            'for' => ['', 'update', 'initialize'],
                            'observee' => (object)[
                                'fields' => ['InitialHCRecDate', 'DateReturned'],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [null, '', 0],
                                'result' => (object)[
                                    'failed' => (object)[
                                        'message' => "Fields 'InitialHCRecDate', 'DateReturned' should have a valid value",
                                        'callback' => 'clearElementValue'
                                    ]
                                ]
                            ]
                        ],
                        (object)[
                            'values' => ['PendingHardcopy'],
                            'for' => ['', 'update', 'initialize'],
                            'observee' => (object)[
                                'fields' => ['InitialHCRecDate'],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [null, '', 0],
                                'result' => (object)[
                                    'failed' => (object)[
                                        'message' => "Fields 'InitialHCRecDate' should have a valid value",
                                        'callback' => 'clearElementValue'
                                    ]
                                ]
                            ]
                        ],
                        (object)[
                            'values' => ['DEFAULT'],
                            'for' => ['', 'initialize'],
                            'observee' => (object)[
                                'fields' => ['DeliveryStatus'],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => (object)[
                                    'default' => [null, '', 0],
                                    'DeliveryStatus' => [
                                        'values' => [
                                            'Booked',
                                            'Cancelled',
                                            'GarageDeparture',
                                            'Intransit',
                                            'Loading&Processing',
                                            'WarehouseArrival',
                                        ],
                                        'message' => "Please select 'Delivered' or 'Irregular' to allow POD status changes"
                                    ],
                                ],
                                'result' => (object)[
                                    'failed' => (object)[
                                        'callback' => 'clearElementValue'
                                    ]
                                ]
                            ]
                        ],
                    ]
                ]
            ],
            'Receivedby' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [],
                            'regex' => '\\S+',
                            'for' => ['update', 'initialize'],
                            'observee' => (object)[
                                'fields' => ['Receivedby'],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [null, '', 0],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'disableFields',
                                        'arg' => (object)[
                                            'fieldNames' => ['Receivedby']
                                        ]
                                    ]
                                ]
                            ]
                        ],
                    ]
                ]
            ],
            'SAPClient' => (object)[
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
                                        'callback' => 'changeOtherFieldApiData',
                                        'arg' => (object)[
                                            'field' => 'ClientName',
                                            'data' => 'CardCodeNames',
                                            'dataField' => 'CardCode',
                                            'value' => 'self',
                                            'targetField' => 'CardName',
                                        ]
                                    ],
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
                                        'callback' => 'changeOtherFieldApiData',
                                        'arg' => (object)[
                                            'field' => 'GroupProject',
                                            'data' => 'CardCodeNames',
                                            'dataField' => 'CardCode',
                                            'value' => 'self',
                                            'targetField' => 'GroupProject',
                                        ]
                                    ],
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'SAPTrucker' => (object)[
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
                                        'callback' => 'changeOtherFieldApiData',
                                        'arg' => (object)[
                                            'field' => 'TruckerName',
                                            'data' => 'CardCodeNames',
                                            'dataField' => 'CardCode',
                                            'value' => 'self',
                                            'targetField' => 'CardName',
                                        ]
                                    ],
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'DeliveryDateDTR' => (object)[
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
                                    'evaluations' => [
                                        (object)[
                                            'callback' => 'isDate1EarlierThanDate2',
                                            'arg' => (object)[
                                                'dateField1' => 'self',
                                                'dateField2' => 'BookingDate',
                                            ],
                                            'failedMessage' => 'DeliveryDateDTR should not be earlier than BookingDate',
                                            'failedMethod' => 'clearElementValue'
                                        ],
                                    ],
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'DeliveryDatePOD' => (object)[
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
                                    'evaluations' => [
                                        (object)[
                                            'callback' => 'isDate1EarlierThanDate2',
                                            'arg' => (object)[
                                                'dateField1' => 'self',
                                                'dateField2' => 'BookingDate',
                                            ],
                                            'failedMessage' => 'DeliveryDatePOD should not be earlier than BookingDate',
                                            'failedMethod' => 'clearElementValue',
                                        ],
                                    ],
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'ActualHCRecDate' => (object)[
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
                                    'evaluations' => [
                                        (object)[
                                            'callback' => 'isDate1EarlierThanDate2',
                                            'arg' => (object)[
                                                'dateField1' => 'self',
                                                'dateField2' => 'DeliveryDateDTR',
                                            ],
                                            'failedMessage' => 'ActualHCRecDate should not be earlier than DeliveryDateDTR',
                                            'failedMethod' => 'clearElementValue',
                                        ],
                                    ],
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'InitialHCRecDate' => (object)[
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
                                    'evaluations' => [
                                        (object)[
                                            'callback' => 'isDate1EarlierThanDate2',
                                            'arg' => (object)[
                                                'dateField1' => 'self',
                                                'dateField2' => 'DeliveryDateDTR',
                                            ],
                                            'failedMessage' => 'InitialHCRecDate should not be earlier than DeliveryDateDTR',
                                            'failedMethod' => 'clearElementValue',
                                        ],
                                    ],
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'VerifiedDateHC' => (object)[
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
                                    'evaluations' => [
                                        (object)[
                                            'callback' => 'isDate1EarlierThanDate2',
                                            'arg' => (object)[
                                                'dateField1' => 'self',
                                                'dateField2' => 'DeliveryDatePOD',
                                            ],
                                            'failedMessage' => 'ActualHCRecDate should not be earlier than DeliveryDatePOD',
                                            'failedMethod' => 'clearElementValue',
                                        ],
                                    ],
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'DateReturned' => (object)[
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
                                    'evaluations' => [
                                        (object)[
                                            'callback' => 'isDate1EarlierThanDate2',
                                            'arg' => (object)[
                                                'dateField1' => 'self',
                                                'dateField2' => 'DeliveryDatePOD',
                                            ],
                                            'failedMessage' => 'DateReturned should not be earlier than DeliveryDatePOD',
                                            'failedMethod' => 'clearElementValue',
                                        ],
                                    ],
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'DeliveryStatus' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [
                                'Booked',
                                'Cancelled',
                                'GarageDeparture',
                                'Intransit',
                                'Loading&Processing',
                                'WarehouseArrival',
                            ],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => [
                                        'callback' => 'clearOtherElementValue',
                                        'arg' => (object)[
                                            'targetField' => 'PODStatusDetail',
                                        ],
                                    ],
                                ]
                            ],
                        ],
                        (object)[
                            'values' => [
                                'Cancelled',
                            ],
                            'for' => ['', 'update', 'initialize'],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => [
                                        'callback' => 'disableFields',
                                        'arg' => (object)[
                                            'fieldNames' => (function ($columns): array {
                                                $observees = [];
                                                foreach ($columns as $column) {
                                                    if (!$this->settings->isImmutableFieldName($column->fieldName)
                                                        && !in_array($column->fieldName, [
                                                            'DeliveryStatus',
                                                        ])
                                                    ) {
                                                        $observees[] = $column->fieldName;
                                                    }
                                                }
                                                return $observees;
                                            })($this->columnDefinitions)
                                        ],
                                    ],
                                ]
                            ],
                        ],
                        (object)[
                            'values' => ['Cancelled'],
                            'for' => ['', 'update', 'initialize'],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'clearOtherElementValue',
                                        'arg' => [
                                            'targetField' => 'PTFNo'
                                        ]
                                    ]
                                ]
                            ]
                        ],
                        (object)[
                            'values' => ['Cancelled'],
                            'for' => ['', 'update', 'initialize'],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'clearOtherElementValue',
                                        'arg' => [
                                            'targetField' => 'DateForwardedBT'
                                        ]
                                    ]
                                ]
                            ]
                        ],
                        (object)[
                            'values' => [
                                'DEFAULT',
                            ],
                            'for' => [''],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => [
                                        'callback' => 'enableFields',
                                        'arg' => (object)[
                                            'fieldNames' => (function ($columns): array {
                                                $observees = [];
                                                foreach ($columns as $column) {
                                                    if (
                                                        !$this->settings->isImmutableFieldName($column->fieldName)
                                                        && !in_array($column->fieldName, [
                                                            'DeliveryStatus',
                                                        ])
                                                        && $column->columnViewType !== ColumnViewType::AUTO
                                                    ) {
                                                        $observees[] = $column->fieldName;
                                                    }
                                                }
                                                return $observees;
                                            })($this->columnDefinitions)
                                        ],
                                    ],
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            // 'TripTicketNo' => (object)[
            //     'events' => [
            //         'onchange' => [
            //             (object)[
            //                 'values' => [],
            //                 'for' => [''],
            //                 'observee' => (object)[
            //                     'fields' => [],
            //                     'acceptedValuesRegex' => '',
            //                     'invalidValues' => [],
            //                     'result' => (object)[
            //                         'evaluations' => [
            //                             (object)[
            //                                 'type' => 'async',
            //                                 'callback' => 'validateFieldApiData',
            //                                 'arg' => (object)[
            //                                     'validation' => 'isDataDuplicate', 
            //                                     'fieldName' => 'TripTicketNo',
            //                                     'targetDataProp' => 'result',
            //                                     'passedValues' => [0, 'n/a', ''],
            //                                     'passedResult' => false,
            //                                 ],
            //                                 'failedMessage' => 'This field should be unique',
            //                                 'failedMethod' => 'clearElementValue',
            //                             ],
            //                             (object)[
            //                                 'callback' => 'isDataDuplicate',
            //                                 'arg' => (object)[
            //                                     'fieldName' => 'TripTicketNo',
            //                                     'passedValues' => [0, 'n/a', ''],
            //                                     'passedResult' => false,
            //                                 ],
            //                                 'failedMessage' => 'This field should be unique',
            //                                 'failedMethod' => 'clearElementValue',
            //                             ],
            //                         ],
            //                     ]
            //                 ],
            //             ],
            //         ]
            //     ]
            // ],
            'WaybillNo' => (object)[
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
                                    'evaluations' => [
                                        (object)[
                                            'type' => 'async',
                                            'callback' => 'validateFieldApiData',
                                            'arg' => (object)[
                                                'validation' => 'isDataDuplicate',
                                                'fieldName' => 'WaybillNo',
                                                'targetDataProp' => 'result',
                                                'passedValues' => [0, '', '0', 'n/a'],
                                                'passedResult' => false,
                                            ],
                                            'failedMessage' => 'This field should be unique',
                                            'failedMethod' => 'clearElementValue',
                                        ],
                                        (object)[
                                            'callback' => 'isDataDuplicate',
                                            'arg' => (object)[
                                                'fieldName' => 'WaybillNo',
                                                'passedValues' => [0, '', '0', 'n/a'],
                                                'passedResult' => false,
                                            ],
                                            'failedMessage' => 'This field should be unique',
                                            'failedMethod' => 'clearElementValue',
                                        ],
                                    ],
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'BillingStatus' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => ['SenttoBT'],
                            'for' => ['', 'update', 'initialize'],
                            'observee' => (object)[
                                'fields' => ['PTFNo'],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [null, '', 0],
                                'result' => (object)[
                                    'failed' => (object)[
                                        'callback' => 'clearElementValue'
                                    ]
                                ]
                            ]
                        ],
                    ]
                ]
            ],
            '_TotalPenaltyWaived' => (object)[
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
                                            'tab' => 'pod',
                                            'refField' => 'Code',
                                            'otherTab' => 'tp',
                                            'foreignField' => 'PODNum',
                                            'field' => 'TotalPenaltyWaived',
                                            'value' => 'self',
                                            'bool' => true
                                        ]
                                    ]
                                ]
                            ],
                        ],
                    ]
                ]
            ],
            'PODSONum' => (object)[
                'events' => [
                    'onchange' => [
                        (object)[
                            'values' => [],
                            'regex' => '\\S+',
                            'for' => ['', 'update', 'initialize'],
                            'observee' => (object)[
                                'fields' => [],
                                'acceptedValuesRegex' => '',
                                'invalidValues' => [],
                                'result' => (object)[
                                    'success' => (object)[
                                        'callback' => 'disableFields',
                                        'arg' => (object)[
                                            'fieldNames' => ['BillingStatus']
                                        ]
                                    ]
                                ]
                            ]
                        ],
                    ]
                ]
            ],
        ];
    }

    protected function postProcessPostingTransaction(object $args): mixed
    {
        return $args;
    }

    protected function preUpdateProcessRows(PctpWindowModel &$model, array $rows): array
    {
        $validatedRows = $rows;
        foreach ($validatedRows as $row) {
            foreach ($row->props as $key => $value) {
                if ($key === 'Attachment') {
                    if ((bool)$value) {
                        if ($row->uploaded === 'no') {
                            throw new PctpError(PctpErrorType::FILE_NOT_UPLOADED);
                        } else if (file_exists($this->settings->getUploadDirectory() . "\\$row->Code\\" . $value)) {
                            $row->props->{$key} = $this->settings->getUploadDirectory() . "\\$row->Code\\" . $value;
                            $model->{$this->tabName . 'Tab'}->realAttachment[] = json_decode(json_encode([
                                'Code' => 'pod' . $row->Code,
                                'realAttachmentPath' => $this->settings->getUploadDirectory() . "\\$row->Code\\"
                            ]));
                        }
                    } else if ((bool)$row->old->{$key}) {
                        if (unlink($this->settings->getUploadDirectory() . "\\$row->Code\\" . basename($row->old->{$key}))) {
                            if (file_exists($this->settings->getUploadDirectory() . "\\$row->Code\\" . basename($row->old->{$key}))) {
                                throw new PctpError(PctpErrorType::FILE_NOT_DELETED);
                            }
                        } else {
                            if (file_exists($this->settings->getUploadDirectory() . "\\$row->Code\\" . basename($row->old->{$key}))) {
                                throw new PctpError(PctpErrorType::FILE_NOT_DELETED);
                            }
                        }
                        $row->props->{$key} = null;
                    }
                }
            }
            if (session_status() === PHP_SESSION_NONE) {
                session_start();
            }
        }
        return $validatedRows;
    }

    protected function postFetchProcessRows(array $rows): array
    {
        return $rows;
    }

    protected function postUpdateProcessRows(PctpWindowModel &$model, array $rows)
    {
        foreach ($rows as $row) {
            $attachment = [];
            foreach ($row->props as $field => $value) {
                if ($field === 'Attachment' && (bool)$value) {
                    $attachment['Code'] = $row->Code;
                    if ((bool)$value) {
                        $attachment['realAttachment'] = $value;
                    }
                }
            }
            if ((bool)$attachment) $this->realAttachment[] = (object)$attachment;
        }
        return $rows;
    }

    private function insertVerifiedPodRowToBilling(object $podTableRow)
    {
        $billingTab = PctpWindowFactory::getObject('PctpWindowController', $_SESSION)->model->billingTab;
        $newBillingTableRow = [];
        foreach ($billingTab->columnDefinitions as $columnDefinition) {
            if ((bool)$columnDefinition->fieldName) {
                if (property_exists($podTableRow, $columnDefinition->fieldName)) {
                    $newBillingTableRow[$columnDefinition->fieldName] = $podTableRow->{$columnDefinition->fieldName};
                } else {
                    $newBillingTableRow[$columnDefinition->fieldName] = null;
                }
            }
        }
        if ((bool)$newBillingTableRow) $billingTab->persistTableRow((object)$newBillingTableRow);
    }

    public function isDataDuplicate(object $arg): bool
    {
        $columnDefinition = $this->getColumnReference('fieldName', $arg->fieldName);
        $column = PctpWindowTabHelper::getInstance($this->settings)->getFormattedNativeColumn(
            $columnDefinition,
            false
        );
        $decoratedValue = '';
        $columnType = !is_null($columnDefinition) ?
            $columnDefinition->columnType
            : null;
        switch ($columnType) {
            case null:
                break;
            case ColumnType::DATE:
                $decoratedValue = (bool)$arg->fieldValue ? "CONVERT(date, '$arg->fieldValue')" : "NULL";
                break;
            case ColumnType::ALPHANUMERIC:
            case ColumnType::TEXT:
                $decoratedValue = "'$arg->fieldValue'";
                break;
            default:
                if (in_array($arg->fieldName, $this->sqlStringColumns)) {
                    $decoratedValue = $arg->fieldValue === '' ? "NULL" : "'$arg->fieldValue'";
                } else {
                    $decoratedValue = $arg->fieldValue === '' ? "NULL" : $arg->fieldValue;
                }
                break;
        }
        return (bool) SAPAccessManager::getInstance()->getRows(
            "   SELECT COUNT(*) AS count
            FROM $this->tableName 
            WHERE $column = $decoratedValue
        "
        )[0]->count;
    }
}
