<?php

require_once __DIR__.'/../inc/restriction.php';

class PctpWindowModel extends ASerializableClass
{
    public string $name = self::class;
    public string $addonName = 'PCTP Window';
    public bool $onDevelopment = true;
    public int $num = 18;
    public string $currentMethod = '';
    public PctpWindowHeader $header;
    public SummaryTab $summaryTab;
    public PodTab $podTab;
    public BillingTab $billingTab;
    public TpTab $tpTab;
    public PricingTab $pricingTab;
    public TreasuryTab $treasuryTab;
    public array $dropDownOptions;
    public array $actionValidations;
    public array $viewOptions;
    public PctpWindowHeader $findHeader;
    public PctpUser $user;
    public bool $isInitialized = false;
    public HybridHeader $hybridHeader;
    public PctpWindowSettings $settings;
    
    public function __construct()
    {
        $this->settings = new PctpWindowSettings();
        $this->hybridHeader = new HybridHeader();
        $this->user = new PctpUser();
        $this->header = new PctpWindowHeader($this->settings);
        $this->summaryTab = new SummaryTab($this->settings);
        $this->podTab = new PodTab($this->settings);
        $this->billingTab = new BillingTab($this->settings);
        $this->tpTab = new TpTab($this->settings);
        $this->pricingTab = new PricingTab($this->settings);
        $this->treasuryTab = new TreasuryTab($this->settings);
        $this->findHeader = new PctpWindowHeader($this->settings);
        $this->dropDownOptions = $this->settings->dropDownOptions;
        $this->viewOptions = $this->settings->viewOptions;
        $this->actionValidations = [
            'update' => (object)[
                'validation' => (object)[
                    'targets' => [
                        [
                            'tab' => 'pod',
                            'checkField' => 'PODStatusDetail',
                            'checkValues' => ['Verified'],
                            'passedValues' => [0, '', null, '0', '0.00'],
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
                        ],
                        [
                            'tab' => 'pod',
                            'checkField' => 'PODStatusDetail',
                            'checkValues' => ['OngoingVerification'],
                            'passedValues' => [0, '', null, '0', '0.00'],
                            'evaluations' => [
                                (object)[
                                    'callback' => 'isDate1EarlierThanDate2',
                                    'arg' => (object)[
                                        'dateField1' => 'InitialHCRecDate', 
                                        'dateField2' => 'DeliveryDateDTR',
                                    ],
                                    'failedMessage' => 'InitialHCRecDate should not be earlier than DeliveryDateDTR/DeliveryDatePOD',
                                    'failedMethod' => 'clearElementValue'
                                ],
                                (object)[
                                    'callback' => 'isDate1EarlierThanDate2',
                                    'arg' => (object)[
                                        'dateField1' => 'ActualHCRecDate', 
                                        'dateField2' => 'DeliveryDateDTR',
                                    ],
                                    'failedMessage' => 'ActualHCRecDate should not be earlier than DeliveryDateDTR/DeliveryDatePOD',
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
                        ],
                        [
                            'tab' => 'pricing',
                            'checkField' => 'GrossClientRates',
                            'checkValues' => [],
                            'passedValues' => [0, '', null, '0', '0.00'],
                            'evaluations' => [
                                (object)[
                                    'callback' => 'isEmpty',
                                    'arg' => (object)[
                                        'subjectField' => 'RateBasis', 
                                    ],
                                    'failedMessage' => 'Rate Basis (Client) is required',
                                ],
                            ],
                        ],
                        [
                            'tab' => 'pricing',
                            'checkField' => 'GrossTruckerRates',
                            'checkValues' => [],
                            'passedValues' => [0, '', null, '0', '0.00'],
                            'evaluations' => [
                                (object)[
                                    'callback' => 'isEmpty',
                                    'arg' => (object)[
                                        'subjectField' => 'RateBasisT', 
                                    ],
                                    'failedMessage' => 'Rate Basis (Trucker) is required',
                                ],
                            ],
                        ],
                    ],
                ]
            ],
        ];
    }

    public function reinitializeModel() {
        $this->header = new PctpWindowHeader($this->settings);
        $this->summaryTab = new SummaryTab($this->settings);
        $this->podTab = new PodTab($this->settings);
        $this->billingTab = new BillingTab($this->settings);
        $this->tpTab = new TpTab($this->settings);
        $this->pricingTab = new PricingTab($this->settings);
        $this->treasuryTab = new TreasuryTab($this->settings);
        $this->findHeader = new PctpWindowHeader($this->settings);
    }

    public function initializeUploadDir(string $identifier): string
    {
        return $this->settings->getUploadDirectory()."/$identifier/";
    }

    public function getSettings(): PctpWindowSettings
    {
        return $this->settings;
        // return $this->settings;
    }

    public function searchRelatedDataRows(APctpWindowTab $tab, array $rows): array
    {
        $relatedDataRows = [];
        foreach ($tab->relatedTables as $relatedTable) {
            $relatedTab = $this->{$relatedTable->tab};
            $relatedDataRow = [];
            $relatedDataRow['tab'] = str_replace('Tab', '', $relatedTable->tab);
            $relatedRows = [];
            foreach ($rows as $row) {
                $relatedRow = [];
                $referenceRow = $tab->getRowReference($row);
                $fetchRows = array_values(array_filter($relatedTab->tableRows, fn($z) => $z->{$relatedTable->foreignField} === $referenceRow->{$relatedTable->ownField}));
                if ((bool)$fetchRows) {
                    $relatedRow[$relatedTab->key] = $fetchRows[0]->{$relatedTab->key};
                    $relatedProps = [];
                    foreach ($row->props as $key => $value) {
                        if (isset($tab->notSameColumns[get_class($relatedTab)]) && in_array($key, $tab->notSameColumns[get_class($relatedTab)])) continue;
                        $columnDefinition = $relatedTab->getColumnReference('fieldName', $key, true);
                        if ($columnDefinition !== null) {
                            $relatedProps[$columnDefinition->fieldName] = $value;
                        }
                    }
                    if ((bool)$relatedProps) {
                        $relatedRow['props'] = $relatedProps;
                    } else {
                        $relatedRow = [];
                    }
                }
                if ((bool)$relatedRow) {
                    $relatedRows[] = $relatedRow;
                }
            }
            if ((bool)$relatedRows) {
                $relatedDataRow['rows'] = $relatedRows;
                $relatedDataRows[] = $relatedDataRow;
            } else {
                $relatedDataRow = [];
            }
        }
        if ((bool)$tab->columnValidations) {
            $relatedDataRows = array_merge($relatedDataRows, $tab->processRelatedUpdates($this, $rows));
        }
        return $relatedDataRows;
    }

    public function getColumnValidations(): array
    {
        $columnValidations = [];
        if ((bool)$this->podTab->columnValidations) $columnValidations['pod'] = $this->podTab->columnValidations;
        if ((bool)$this->billingTab->columnValidations) $columnValidations['billing'] = $this->billingTab->columnValidations;
        if ((bool)$this->tpTab->columnValidations) $columnValidations['tp'] = $this->tpTab->columnValidations;
        if ((bool)$this->pricingTab->columnValidations) $columnValidations['pricing'] = $this->pricingTab->columnValidations;
        if ((bool)$this->treasuryTab->columnValidations) $columnValidations['treasury'] = $this->treasuryTab->columnValidations;
        return $columnValidations;
    }

    public function getColumnDefinitions(): array
    {
        $columnDefinitions = [];
        $columnDefinitions['summary'] = $this->summaryTab->columnDefinitions;
        $columnDefinitions['pod'] = $this->podTab->columnDefinitions;
        $columnDefinitions['billing'] = $this->billingTab->columnDefinitions;
        $columnDefinitions['tp'] = $this->tpTab->columnDefinitions;
        $columnDefinitions['pricing'] = $this->pricingTab->columnDefinitions;
        $columnDefinitions['treasury'] = $this->treasuryTab->columnDefinitions;
        return $columnDefinitions;
    }

    public function processHybridHeader(): void {
        $this->hybridHeader->viewOptions = $this->viewOptions;
        $this->hybridHeader->sapDocumentStructures = $this->getSettings()->sapDocumentStructures;
        $this->hybridHeader->uploadedAttachment = [
            'pod' => $this->podTab->getAttachmentObjs($this->header),
            'billing' => $this->billingTab->getAttachmentObjs($this->header),
            'tp' => $this->tpTab->getAttachmentObjs($this->header),
        ];
        $this->hybridHeader->actionValidations = $this->actionValidations;
        $this->hybridHeader->columnValidations = $this->getColumnValidations();
        $this->hybridHeader->columnDefinitions = $this->getColumnDefinitions();
        $this->hybridHeader->dropDownOptions = $this->getSettings()->dropDownOptions;
        $this->hybridHeader->constants = $this->getSettings()->constants;
    }
}