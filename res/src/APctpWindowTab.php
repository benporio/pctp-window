<?php

require_once __DIR__ . '/../inc/restriction.php';

abstract class APctpWindowTab extends ASerializableClass
{
    public array $columnDefinitions;
    public array $tableRows;
    public array $columnValidations = [];
    public array $optionalFields = [];
    protected array $columnsNeedUtf8Conversion = [];
    public array $relatedTables = [];
    public array $similarFields = [];
    public array $sapDocumentStructureTypes = [];
    public array $sapObjs = [];
    public string $defaultFetchFilterClause = '';
    public array $fieldConstants = [];
    public string $script = '';
    public string $extractScript = '';
    public array $preFetchRefreshScripts = [];
    public array $fieldDatesToFormat = [];
    protected object $uploadedAttachment;
    public array $realAttachment = [];
    public array $foreignFields = [];
    public string $tabName;
    public object $fieldEnumValues;
    public int $fetchTableRowsCount = 0;
    public PctpWindowHeader $findHeader;
    public array $sqlStringColumns = [];
    public array $similarColumns = [];
    public array $notSameColumns = [];
    public array $fieldsFindOptions = [];
    public array $searchableFields = [];
    public array $disableSomeFields = [];
    public array $updateFieldAlias = [];
    public string $methodTrack = '';
    public array $excludeFromWildCardSearch = [];
    public PctpWindowSettings $settings;

    protected function __construct(
        public string $key,
        protected string $tableName,
        PctpWindowSettings $settings
    ) {
        $this->settings = $settings;
        $this->similarColumns = json_decode(file_get_contents(__DIR__ . '/../json/similar_columns.json'));
        $this->tableRows = [];
        $this->findHeader = new PctpWindowHeader($settings);
        $this->tabName = strtolower(str_replace('Tab', '', get_class($this)));
        $this->fetchTableRowsCount = PctpWindowTabHelper::getInstance($this->settings)->countFetchTableRows(
            $this,
            $this->tableName,
            $this->createFilterClauseChunks(new PctpWindowHeader($settings), '')
        );
        $this->uploadedAttachment = (object)[];
        $this->fieldEnumValues = (object)[];
    }

    public function storeHeaderData(PctpWindowModel &$model, object $rawHeader)
    {
        if ($this->settings->viewOptions['data_table_common_find_header']) {
            $model->findHeader = PctpWindowHeader::parseHeader($rawHeader, $this->settings);
        } else {
            $this->findHeader = PctpWindowHeader::parseHeader($rawHeader, $this->settings);
        }
    }

    public function countFetchTableRows(PctpWindowHeader $header)
    {
        $this->fetchTableRowsCount = PctpWindowTabHelper::getInstance($this->settings)->countFetchTableRows($this, $this->tableName, $this->createFilterClauseChunks($header, $this->settings->defaultSQLMainTableAlias, true));
    }

    public function getAttachmentObjs(PctpWindowHeader $header): object
    {
        if (!in_array(get_class($this), ['PodTab', 'BillingTab', 'TpTab'])) return (object)[];
        $this->methodTrack = 'getAttachmentObjs';
        $filterClause = '';
        $filterClauseChunks = $this->createFilterClauseChunks($header, str_replace('tab', '', strtolower(get_class($this))), true);
        if ((bool)$this->defaultFetchFilterClause) $filterClauseChunks[] = $this->defaultFetchFilterClause;
        if ((bool)$filterClauseChunks) {
            $filterClauseChunks = array_map(
                fn ($z) => preg_replace(
                    $this->settings->columnValidRegexPrefix . $this->settings->defaultSQLColumnPrefix . '/i',
                    get_class($this) . '.' . $this->settings->defaultSQLColumnPrefix,
                    $z
                ),
                $filterClauseChunks
            );
            $filterClause = ' WHERE ' . join(' AND ', $filterClauseChunks);
        }
        $script = file_get_contents(__DIR__ . '/../sql/attachment.sql');
        if ($this->extractScript !== '' && str_contains($filterClause, 'LIKE')) {
            $bookingIds = $this->getBookingIdsFilter(false, $filterClause);
            if ((bool)$bookingIds) {
                $bookingIdsStr = "'" . join("','", $bookingIds) . "'";
                $bookingIdColumn = $this->getTabColumnFindOption($this->getColumnReference('fieldName', 'BookingId'), strtolower(str_replace('Tab', '', get_class($this))), false);
                $filterClause = 'WHERE ' . $bookingIdColumn . " IN ($bookingIdsStr) ";
            }
        }
        $tableRows = SAPAccessManager::getInstance()->getRows("$script $filterClause");
        PctpWindowTabHelper::getInstance($this->settings)->setAttachmentsBasenames($this, $tableRows, true, get_class($this) . 'Code');
        $uploadedAttachment = [];
        foreach ($tableRows as $row) {
            foreach ((array)$row as $key => $value) {
                if ($key === 'Attachment') {
                    if (!isset($row->{get_class($this) . 'Code'})) continue;
                    $uploadedAttachment[$row->{get_class($this) . 'Code'}] = [
                        'attachment' => $value === null ? '' : $value,
                        'upload' => null,
                        'uploaded' => 'no',
                        'removed' => 'no'
                    ];
                }
            }
        }
        $this->methodTrack = '';
        return (object)$uploadedAttachment;
    }

    private function getTabColumnOrderOption(int $columnIndex): string
    {
        $aliasPrefix = '';
        $columnDefinition = $this->columnDefinitions[$columnIndex];
        if (isset($this->fieldsFindOptions[$columnDefinition->fieldName])) {
            $fieldFindOption = $this->fieldsFindOptions[$columnDefinition->fieldName];
            if (isset($fieldFindOption['involveInOrderBy']) && $fieldFindOption['involveInOrderBy']) {
                return $fieldFindOption['alias'] . '.' . (isset($fieldFindOption['needColumnFormat']) && !$fieldFindOption['needColumnFormat'] ? $fieldFindOption['field'] : PctpWindowTabHelper::getInstance($this->settings)->getNativeColumnEquivalent(
                    $fieldFindOption['field']
                ));
            }
        }
        $aliasPrefix = in_array($columnDefinition->fieldName, $this->foreignFields) ?  '' : $this->settings->defaultSQLMainTableAlias;
        $nativeColumn = $this->getTabColumnFindOption($columnDefinition, $aliasPrefix, true);
        // $nativeColumn = PctpWindowTabHelper::getInstance($this->settings)->getFormattedNativeColumn(
        //     $columnDefinition,
        //     false,
        //     $aliasPrefix
        // );
        return $nativeColumn;
    }

    public function getBookingIdsFilterClause(string $filterClause): string
    {
        $bookingIds = $this->getBookingIdsFilter(false, $filterClause);
        if ((bool)$bookingIds) {
            $bookingIdsStr = "'" . join("','", $bookingIds) . "'";
            $bookingIdColumn = $this->getTabColumnFindOption($this->getColumnReference('fieldName', 'BookingId'), '', false);
            return 'WHERE ' . $bookingIdColumn . " IN ($bookingIdsStr) ";
        }
        return '';
    }

    private function getFilteredBookingIds(bool $enableFieldsFindOptions, string $filterClause, string $orderClause = '', string $offsetClause = ''): array
    {
        $bookingIdColumn = $this->getTabColumnFindOption($this->getColumnReference('fieldName', 'BookingId'), '', $enableFieldsFindOptions);
        $bookingIdScript = $this->extractScript;
        $bookingIdScript = preg_replace('/--COLUMNS[\s\S]+--COLUMNS/', "$bookingIdColumn AS BookingId", $bookingIdScript);
        $newFilterClause = preg_replace('/\s[A-Za-z0-9]+\./', ' ', $filterClause);
        $newOrderClause = preg_replace('/\s[A-Za-z0-9]+\./', ' ', $orderClause);
        $preScript = "$bookingIdScript \n$newFilterClause \n$newOrderClause \n$offsetClause";
        return SAPAccessManager::getInstance()->getRows($preScript);
    }

    private function getBookingIdsFilter(bool $enableFieldsFindOptions, string $filterClause, string $orderClause = '', string $offsetClause = ''): array
    {
        $bookingIdColumn = $this->getTabColumnFindOption($this->getColumnReference('fieldName', 'BookingId'), '', $enableFieldsFindOptions);
        $bookingIdScript = $this->extractScript;
        $bookingIdScript = preg_replace('/--COLUMNS[\s\S]+--COLUMNS/', "$bookingIdColumn AS BookingId", $bookingIdScript);
        $newFilterClause = preg_replace('/\s[A-Za-z0-9]+\./', ' ', $filterClause);
        $newOrderClause = preg_replace('/\s[A-Za-z0-9]+\./', ' ', $orderClause);
        $preScript = "$bookingIdScript \n$newFilterClause \n$newOrderClause \n$offsetClause";
        $bookingIds = SAPAccessManager::getInstance()->getRows($preScript);
        return array_map(fn ($z) => $z->BookingId, $bookingIds);
    }

    public function manipulateJoinTablesInExtract(string $filterClause, string &$bookingIdScript) {
        if (str_contains($filterClause, 'BE.')) {
            $bookingIdScript .= " LEFT JOIN BILLING_EXTRACT BE ON BE.U_BookingNumber = ";
            if (in_array($this::class, [PodTab::class, SummaryTab::class])) {
                $bookingIdScript .= " X.U_BookingNumber ";
            } else {
                $bookingIdScript .= " X.U_BookingId ";
            }
        }
        if (str_contains($filterClause, 'TF.')) {
            $bookingIdScript .= " LEFT JOIN TP_FORMULA TF ON TF.U_BookingId = ";
            if (in_array($this::class, [PodTab::class, SummaryTab::class])) {
                $bookingIdScript .= " X.U_BookingNumber ";
            } else {
                $bookingIdScript .= " X.U_BookingId ";
            }
        }
    }

    public function fetchRows(PctpWindowHeader $header, object $dataTableSetting = null, bool $doAssignToTableRows = true, bool $doPreFetchProcess = true): array
    {
        if ($this->fetchTableRowsCount === 0) {
            $this->tableRows = [];
            return [];
        }
        $tableAlias = (bool)$this->script ? $this->settings->defaultSQLMainTableAlias : '';
        $enableFieldsFindOptions = true;
        $partialTableRows = [];
        $orderClause = $this->settings->defaultOrderClause;
        $orderClause = str_replace('T0.U_BookingDate', $this->getTabColumnFindOption($this->getColumnReference('fieldName', 'BookingDate'), $tableAlias, $enableFieldsFindOptions), $orderClause);
        $offsetClause = '';
        if (!is_null($dataTableSetting)) {
            $offset = $this->settings->viewOptions['use_data_table_setting_length'] ?
                $dataTableSetting->length : $this->settings->viewOptions['data_table_page_length'];
            $page = intval($dataTableSetting->start) / intval($offset);
            $offsetClause = "OFFSET ($offset*$page) ROWS FETCH NEXT $offset ROWS ONLY";
            if (isset($dataTableSetting->order)) {
                $orders = [];
                foreach ($dataTableSetting->order as $order) {
                    $columnIndex = get_class($this) === 'SummaryTab' ? $order['column'] - 1 : $order['column'] - 2;
                    $nativeColumn = $this->getTabColumnOrderOption($columnIndex);
                    $dir = $order['dir'];
                    $orders[] = "$nativeColumn $dir";
                }
                $orderClause = 'ORDER BY ' . join(",\r\n", $orders);
            }
        }
        $filterClause = '';
        $filterClauseChunks = $this->createFilterClauseChunks($header, $tableAlias, $enableFieldsFindOptions);
        if ((bool)$this->defaultFetchFilterClause) $filterClauseChunks[] = $this->defaultFetchFilterClause;
        if ((bool)$filterClauseChunks) {
            if ((bool)$this->script) {
                $filterClauseChunks = array_map(
                    fn ($z) => preg_replace(
                        $this->settings->columnValidRegexPrefix . $this->settings->defaultSQLColumnPrefix . '/i',
                        $this->settings->defaultSQLMainTableAlias . '.' . $this->settings->defaultSQLColumnPrefix,
                        $z
                    ),
                    $filterClauseChunks
                );
            }
            $filterClause = 'WHERE ' . join(" \r\nAND ", $filterClauseChunks);
        }
        if (!(bool)$this->script) {
            $columns = join(', ', array_map(
                fn ($b) => PctpWindowTabHelper::getInstance($this->settings)->getFormattedNativeColumn($b, true),
                array_values(array_filter($this->columnDefinitions, fn ($a) => !$this->settings->isImmutableFieldName($a->fieldName)))
            ));
            $limit = $this->settings->fetchRowLimit;
            $limitClause = $limit > 0 ? " TOP $limit " : '';
            $partialTableRows = SAPAccessManager::getInstance()->getRows(
                "   SELECT $limitClause $this->key, $columns 
                FROM $this->tableName
                $filterClause
                $orderClause
                $offsetClause
            "
            );
        } else {
            $script = $this->script;
            $bookingIdsStr = '';
            $bookingIdColumn = '';
            $bookingIds = [];
            $doFetchFromExtract = isset($this->settings->config['enable_fetch_from_extract']) && $this->settings->config['enable_fetch_from_extract'];
            $doRefreshExtractWhenFetching = !(isset($this->settings->config['disable_refresh_extract_when_fetching']) && $this->settings->config['disable_refresh_extract_when_fetching']);
            if ($this->extractScript !== '') {
                $bookingIdScript = $this->extractScript;
                $hasAppendedCustomAlias = false;
                $appendedCustomAlias = '';
                if (str_contains($filterClause, 'billing.')) $filterClause = str_replace('billing.', ' BE.', $filterClause);
                if (str_contains($filterClause, 'BE.') || str_contains($filterClause, 'TF.')) {
                    $hasAppendedCustomAlias = true;
                    $appendedCustomAlias = 'X';
                    $this->manipulateJoinTablesInExtract($filterClause, $bookingIdScript);
                    $newFilterClause = str_replace(['T0.', 'pod.'], ' X.', $filterClause);
                    $newOrderClause = str_replace(['T0.', 'pod.'], ' X.', $orderClause);
                } else {
                    $newFilterClause = preg_replace('/\s[A-Za-z0-9]+\./', ' ', $filterClause);
                    $newOrderClause = preg_replace('/\s[A-Za-z0-9]+\./', ' ', $orderClause);
                }
                $bookingIdColumn = $this->getTabColumnFindOption($this->getColumnReference('fieldName', 'BookingId'), $hasAppendedCustomAlias ? $appendedCustomAlias : '', $enableFieldsFindOptions);
                if ($doFetchFromExtract) {
                    $preScript = "$bookingIdScript \n$newFilterClause \n$newOrderClause \n$offsetClause";
                    $partialTableRows = SAPAccessManager::getInstance()->getRows($preScript);
                    if ($doPreFetchProcess && $doRefreshExtractWhenFetching) $this->preFetchProcess(array_map(fn ($z) => (object)[ 'BookingId' => isset($z->U_BookingId) ? $z->U_BookingId : $z->U_BookingNumber], $partialTableRows));
                } else {
                    $bookingIdScript = preg_replace('/--COLUMNS[\s\S]+--COLUMNS/', "$bookingIdColumn AS BookingId", $bookingIdScript);
                    $preScript = "$bookingIdScript \n$newFilterClause \n$newOrderClause \n$offsetClause";
                    $bookingIds = SAPAccessManager::getInstance()->getRows($preScript);
                    $bookingIdsStr = "'" . join("','", array_map(fn ($z) => $z->BookingId, $bookingIds)) . "'";
                }
            } else {
                $bookingIdColumn = $this->getTabColumnFindOption($this->getColumnReference('fieldName', 'BookingId'), $tableAlias, $enableFieldsFindOptions);
                $bookingIdScript = preg_replace('/--COLUMNS[\s\S]+--COLUMNS/', "$bookingIdColumn AS BookingId", $script);
                $preScript = "$bookingIdScript \n$filterClause \n$orderClause \n$offsetClause";
                $bookingIds = SAPAccessManager::getInstance()->getRows($preScript);
                $bookingIdsStr = "'" . join("','", array_map(fn ($z) => $z->BookingId, $bookingIds)) . "'";
            }
            if (!(bool)$partialTableRows) {
                if ($this->methodTrack === 'getTableRowsDataWithHeaders' && $this->extractScript !== '') {
                    $bookingIdColumn = $this->getTabColumnFindOption($this->getColumnReference('fieldName', 'BookingId'), '', $enableFieldsFindOptions);
                    $filterClause = 'WHERE ' . $bookingIdColumn . " IN ($bookingIdsStr) ";
                    $script = $this->extractScript;
                    $orderClause = str_replace(['T0.', 'pod.'], '', $orderClause);
                } else {
                    $bookingIdColumn = $this->getTabColumnFindOption($this->getColumnReference('fieldName', 'BookingId'), $tableAlias, $enableFieldsFindOptions);
                    $filterClause = 'WHERE ' . $bookingIdColumn . " IN ($bookingIdsStr) ";
                }
                $finalScript = "$script \n$filterClause \n$orderClause";
                if ($doPreFetchProcess && $doRefreshExtractWhenFetching) $this->preFetchProcess($bookingIds);
                if ($_SERVER['REMOTE_ADDR'] === '::1') file_put_contents(__DIR__ . '/../sql/tmp/debug.sql', $finalScript);
                $partialTableRows = SAPAccessManager::getInstance()->getRows($finalScript);
            }
        }

        $this->tableRows = [];
        if ((bool)$partialTableRows) {
            foreach ($partialTableRows as $row) {
                $newRow = [];
                foreach ((array)$row as $key => $value) {
                    $key = str_replace('U_', '', $key);
                    if ((bool)$this->columnsNeedUtf8Conversion && count(array_filter($this->columnsNeedUtf8Conversion, fn ($a) => $a === $key))) {
                        $newRow[$key] = utf8_encode($value);
                    } else {
                        $newRow[$key] = $value;
                    }
                }
                $this->tableRows[] = (object)$newRow;
            }
        }
        $resultTableRows = $this->screenFetchedRows($this->tableRows);
        if ($doAssignToTableRows) $this->tableRows = $resultTableRows;
        return $resultTableRows;
    }

    private function getTabColumnFindOption(ColumnDefinition $columnDefinition, string $tableAlias, bool $enableFieldsFindOptions): string | array
    {
        if ($enableFieldsFindOptions && isset($this->fieldsFindOptions[$columnDefinition->fieldName])) {
            $fieldFindOption = $this->fieldsFindOptions[$columnDefinition->fieldName];
            if (isset($fieldFindOption['notInMethodTrack']) && $this->methodTrack !== '' && $fieldFindOption['notInMethodTrack'] === $this->methodTrack) return '';
            if (isset($fieldFindOption['involveInFindText']) && $fieldFindOption['involveInFindText']) {
                if (is_array($fieldFindOption['alias'])) {
                    return array_map(fn ($z) => $z . '.' . (isset($fieldFindOption['needColumnFormat']) && !$fieldFindOption['needColumnFormat'] ? $fieldFindOption['field'] : PctpWindowTabHelper::getInstance($this->settings)->getNativeColumnEquivalent(
                        $fieldFindOption['field']
                    )), $fieldFindOption['alias']);
                }
                return $fieldFindOption['alias'] . '.' . (isset($fieldFindOption['needColumnFormat']) && !$fieldFindOption['needColumnFormat'] ? $fieldFindOption['field'] : PctpWindowTabHelper::getInstance($this->settings)->getNativeColumnEquivalent(
                    $fieldFindOption['field']
                ));
            }
            return PctpWindowTabHelper::getInstance($this->settings)->getFormattedNativeColumn($columnDefinition, false, in_array($columnDefinition->fieldName, $this->foreignFields) ? '' : $tableAlias);
        } else return PctpWindowTabHelper::getInstance($this->settings)->getFormattedNativeColumn($columnDefinition, false, in_array($columnDefinition->fieldName, $this->foreignFields) ? '' : $tableAlias);
    }

    private function createFilterClauseChunks(PctpWindowHeader $data, string $tableAlias = '', bool $enableFieldsFindOptions = false): array
    {
        $filterClauseChunks = [];
        if ((bool)$data->findText) {
            $filterClauseChunks[] = ' ( ' . join(
                " \r\nOR ",
                array_filter(
                    array_map(
                        function ($b) use ($data, $tableAlias, $enableFieldsFindOptions) {
                            $column = $this->getTabColumnFindOption($b, $tableAlias, $enableFieldsFindOptions);
                            if ($column === '') {
                                return '';
                            } else {
                                return $this->getTabColumnFindOption($b, $tableAlias, $enableFieldsFindOptions) . " LIKE '%" . SAPAccessManager::getInstance()->validateStringArgForQuery($data->findText) . "%'";
                            }
                        },
                        array_filter(
                            $this->columnDefinitions,
                            fn ($a) => ($a->columnType === ColumnType::ALPHANUMERIC
                                && !$this->settings->isImmutableFieldName($a->fieldName)
                                && !in_array($a->fieldName, $this->foreignFields)
                                && !in_array($a->fieldName, $this->excludeFromWildCardSearch))
                                || (in_array($a->fieldName, $this->searchableFields) && !in_array($a->fieldName, $this->excludeFromWildCardSearch))
                        )
                    ),
                    fn ($c) => $c !== ''
                )
            ) . ') ';
        }
        $column = $this->getTabColumnFindOption($this->getColumnReference('fieldName', 'BookingDate'), $tableAlias, $enableFieldsFindOptions);
        if ((bool)$data->bookingDateFrom && (bool)$data->bookingDateTo && (bool)$column) {
            $filterClauseChunks[] = " ( $column >= CONVERT(date, '$data->bookingDateFrom') AND $column <= CONVERT(date, '$data->bookingDateTo')) ";
        } else if (((bool)$data->bookingDateFrom || (bool)$data->bookingDateTo) && (bool)$column) {
            if ((bool)$data->bookingDateFrom) {
                $filterClauseChunks[] = " ( $column >= CONVERT(date, '$data->bookingDateFrom')) ";
            } else if ((bool)$data->bookingDateTo) {
                $filterClauseChunks[] = " ( $column <= CONVERT(date, '$data->bookingDateTo')) ";
            }
        }
        $column = PctpWindowTabHelper::getInstance($this->settings)->getFormattedNativeColumn($this->getColumnReference('fieldName', 'DeliveryDateDTR'), false, $tableAlias);
        if ((bool)$data->deliveryDateFrom && (bool)$data->deliveryDateTo && (bool)$column) {
            $filterClauseChunks[] = " ( $column >= CONVERT(date, '$data->deliveryDateFrom') AND $column <= CONVERT(date, '$data->deliveryDateTo')) ";
        } else if (((bool)$data->deliveryDateFrom || (bool)$data->deliveryDateTo) && (bool)$column) {
            if ((bool)$data->deliveryDateFrom) {
                $filterClauseChunks[] = " ( $column >= CONVERT(date, '$data->deliveryDateFrom')) ";
            } else if ((bool)$data->deliveryDateTo) {
                $filterClauseChunks[] = " ( $column <= CONVERT(date, '$data->deliveryDateTo')) ";
            }
        }

        if ((bool)$data->clientTag && ($this->doesColumnExist('SAPClient') || ($enableFieldsFindOptions && isset($this->fieldsFindOptions['SAPClient'])))) {
            $column = '';
            if ($enableFieldsFindOptions && isset($this->fieldsFindOptions['SAPClient'])) {
                $column = $this->fieldsFindOptions['SAPClient']['alias'] . '.' . PctpWindowTabHelper::getInstance($this->settings)->getNativeColumnEquivalent(
                    $this->fieldsFindOptions['SAPClient']['field']
                );
            } else {
                $columnDefinition = $this->getColumnReference('fieldName', 'SAPClient');
                $column = $enableFieldsFindOptions && (bool)$this->fieldsFindOptions && isset($this->fieldsFindOptions[$columnDefinition->fieldName]) ?
                    $this->fieldsFindOptions[$columnDefinition->fieldName]['alias'] . '.' . PctpWindowTabHelper::getInstance($this->settings)->getNativeColumnEquivalent(
                        $this->fieldsFindOptions[$columnDefinition->fieldName]['field']
                    ) :
                    PctpWindowTabHelper::getInstance($this->settings)->getFormattedNativeColumn(
                        $columnDefinition,
                        false,
                        $tableAlias
                    );
            }
            $filterClauseChunks[] = " ( $column LIKE '$data->clientTag') ";
        }
        if ((bool)$data->truckerTag && ($this->doesColumnExist('SAPTrucker') || ($enableFieldsFindOptions && isset($this->fieldsFindOptions['SAPTrucker'])))) {
            $column = '';
            if ($enableFieldsFindOptions && isset($this->fieldsFindOptions['SAPTrucker'])) {
                $column = $this->fieldsFindOptions['SAPTrucker']['alias'] . '.' . PctpWindowTabHelper::getInstance($this->settings)->getNativeColumnEquivalent(
                    $this->fieldsFindOptions['SAPTrucker']['field']
                );
            } else {
                $columnDefinition = $this->getColumnReference('fieldName', 'SAPTrucker');
                $column = $enableFieldsFindOptions && (bool)$this->fieldsFindOptions && isset($this->fieldsFindOptions[$columnDefinition->fieldName]) ?
                    $this->fieldsFindOptions[$columnDefinition->fieldName]['alias'] . '.' . PctpWindowTabHelper::getInstance($this->settings)->getNativeColumnEquivalent(
                        $this->fieldsFindOptions[$columnDefinition->fieldName]['field']
                    ) :
                    PctpWindowTabHelper::getInstance($this->settings)->getFormattedNativeColumn(
                        $columnDefinition,
                        false,
                        $tableAlias
                    );
            }
            $filterClauseChunks[] = " ( $column LIKE '$data->truckerTag') ";
        }
        if ((bool)$data->deliveryStatusOptions && $this->doesColumnExist('DeliveryStatus')) {
            $column = PctpWindowTabHelper::getInstance($this->settings)->getFormattedNativeColumn($this->getColumnReference('fieldName', 'DeliveryStatus'), false, $tableAlias);
            $filterClauseChunks[] = " ( $column = '$data->deliveryStatusOptions') ";
        }
        if ((bool)$data->podStatusOptions && $this->doesColumnExist('PODStatusDetail')) {
            $column = PctpWindowTabHelper::getInstance($this->settings)->getFormattedNativeColumn($this->getColumnReference('fieldName', 'PODStatusDetail'), false, $tableAlias);
            $filterClauseChunks[] = " ( $column = '$data->podStatusOptions') ";
        }
        if (($data->includeBlankBillingStatusOnly || (bool)$data->billingStatusOptions) && $this->doesColumnExist('BillingStatus')) {
            $column = $this->getTabColumnFindOption($this->getColumnReference('fieldName', 'BillingStatus', true), $tableAlias, $enableFieldsFindOptions);
            if (is_string($column) && $column !== '') {
                $filterClauseChunks[] = $data->includeBlankBillingStatusOnly ? " ( $column IS NULL OR $column = '' ) " :  " ( $column = '$data->billingStatusOptions' ) ";
            } else if (is_array($column)) {
                $filter = '';
                if ($data->includeBlankBillingStatusOnly) {
                    $filter = " ( " . join('AND', array_map(fn ($z) => " ( $z IS NULL OR $z = '' ) ", $column)) . " ) ";
                } else if (in_array(get_class($this), ['PodTab', 'BillingTab', 'SummaryTab'])) {
                    $filter = " (BE.U_BillingStatus = '$data->billingStatusOptions' OR ((BE.U_BillingStatus = '' OR BE.U_BillingStatus IS NULL) AND T0.U_BillingStatus = '$data->billingStatusOptions')) ";
                }
                $filterClauseChunks[] = $filter;
            }
        }
        if (($data->includePtfNo || (bool)$data->ptfNo) && $this->doesColumnExist('PTFNo')) {
            $column = PctpWindowTabHelper::getInstance($this->settings)->getFormattedNativeColumn($this->getColumnReference('fieldName', 'PTFNo'), false, $tableAlias);
            $filterClauseChunks[] = (bool)$data->ptfNo ? " ( $column = '$data->ptfNo') " : " ( $column IS NULL OR $column = '') ";
        }
        if (($data->includeBlankSIRefOnly || (bool)$data->siRef) && $this->doesColumnExist('SINo', true)) {
            $column = $this->getTabColumnFindOption($this->getColumnReference('fieldName', 'SINo', true), $tableAlias, $enableFieldsFindOptions);
            if ($column !== '') $filterClauseChunks[] = (bool)$data->includeBlankSIRefOnly ? " ( $column IS NULL OR $column = '') " : " ( $column = '$data->siRef') ";
        }
        if (($data->includeBlankSODocNumOnly || (bool)$data->soDocNum) && $this->doesColumnExist('PODSONum')) {
            $column = $this->getTabColumnFindOption($this->getColumnReference('fieldName', 'PODSONum', true), $tableAlias, $enableFieldsFindOptions);
            $filterClauseChunks[] = (bool)$data->includeBlankSODocNumOnly ? " ( $column IS NULL OR $column = '' OR EXISTS(SELECT 1 FROM ORDR header WHERE header.DocNum = $column AND header.CANCELED = 'Y')) " : " ( $column = '$data->soDocNum' AND NOT EXISTS(SELECT 1 FROM ORDR header WHERE header.DocNum = $column AND header.CANCELED = 'Y')) ";
        }
        if (($data->includeBlankARDocNumOnly || (bool)$data->arDocNum) && $this::class !== TreasuryTab::class) {
            if ($data->includeBlankARDocNumOnly && $this->methodTrack !== 'getAttachmentObjs') {
                $filterClauseChunks[] = " (BE.U_DocNum IS NULL OR BE.U_DocNum = '') ";
            } else {
                $bookingIdWithARs = array_map(
                    fn ($z) => $z->ItemCode,
                    SAPAccessManager::getInstance()->getRows(
                        "   SELECT line.ItemCode
                        FROM INV1 line
                        LEFT JOIN OINV header ON header.DocEntry = line.DocEntry
                        WHERE header.CANCELED <> 'Y' AND line.ItemCode IS NOT NULL AND line.ItemCode <> ''
                        AND header.DocNum = '$data->arDocNum'
                    "
                    )
                );
                $bookingIdWithARs = "'" . join("','", $bookingIdWithARs) . "'";
                $column = PctpWindowTabHelper::getInstance($this->settings)->getFormattedNativeColumn($this->getColumnReference('fieldName', 'BookingNumber'), false, $tableAlias);
                $filterClauseChunks[] = " ( $column IN ($bookingIdWithARs)) ";
            }
        }
        if (($data->includeBlankAPDocNumOnly || (bool)$data->apDocNum) && $this::class !== TreasuryTab::class) {
            if ($data->includeBlankAPDocNumOnly && $this->methodTrack !== 'getAttachmentObjs') {
                $filterClauseChunks[] = " ((TF.U_DocNum IS NULL OR TF.U_DocNum = '') AND (TF.U_Paid IS NULL OR TF.U_Paid = '')) ";
            } else {
                $bookingIdWithAPs = array_map(
                    fn ($z) => $z->BookingId,
                    SAPAccessManager::getInstance()->getRows(
                        "   SELECT U_BookingId AS BookingId
                        FROM TP_FORMULA
                        WHERE (U_DocNum LIKE '%[ ]$data->apDocNum%' OR U_Paid LIKE '%[ ]$data->apDocNum%')
                    "
                    )
                );
                $bookingIdWithAPs = "'" . join("','", $bookingIdWithAPs) . "'";
                $column = PctpWindowTabHelper::getInstance($this->settings)->getFormattedNativeColumn($this->getColumnReference('fieldName', 'BookingNumber'), false, $tableAlias);
                $filterClauseChunks[] = " ( $column IN ($bookingIdWithAPs)) ";
            }
        }
        return $filterClauseChunks;
    }

    public function updateRows(PctpWindowModel &$model, array $rows, bool $doPreFetchProcess = true): bool
    {
        $this->preUpdateProcess($rows);
        if (SAPAccessManager::getInstance()->directUpdateTable($this->tableName, $this->preUpdateProcessRows($model, $rows), $this)) {
            $this->postUpdateProcess($model, $rows, $doPreFetchProcess);
            return true;
        }
        return false;
    }

    private function preUpdateProcess(array &$rows)
    {
        foreach ($rows as $row) {
            foreach ($row->props as $key => $value) {
                if ((bool)$this->foreignFields && in_array($key, $this->foreignFields)) {
                    unset($row->props->{$key});
                }
            }
            switch (get_class($this)) {
                case 'PodTab':
                    $row->props->PODinCharge = $_SESSION['SESS_USERCODE'];
                    break;
                case 'TpTab':
                    $row->props->TPincharge = $_SESSION['SESS_USERCODE'];
                    break;
                default:
                    # code...
                    break;
            }
        }
    }

    public function getRowReference(object $row, bool $getFreshData = false): ?object
    {
        if (!$getFreshData) {
            $result = array_values(array_filter($this->tableRows, fn ($z) => $z->{$this->key} === $row->{$this->key}));
            if ((bool)$result && isset($result[0])) return $result[0];
        }
        $column = '';
        if (isset($this->updateFieldAlias) && count($this->updateFieldAlias) && isset($this->updateFieldAlias[$this->key])) {
            $column = $this->getColumnReference('fieldName', $this->updateFieldAlias[$this->key]);
        } else {
            $column = $this->getColumnReference('fieldName', $this->key);
        }
        if (is_null($column)) {
            $whereClause = ' WHERE ' . $this->settings->defaultSQLMainTableAlias . '.' . PctpWindowTabHelper::getInstance($this->settings)->getNativeColumnEquivalent($this->key) . ' = \'' . $row->{$this->key} . "'";
        } else {
            $whereClause = ' WHERE ' . PctpWindowTabHelper::getInstance($this->settings)->getFormattedNativeColumn($column, false, $this->settings->defaultSQLMainTableAlias) . ' = \'' . $row->{$this->key} . "'";
        }
        return $this->getRowReferenceByScript($whereClause);
    }

    public function getRowReferenceByKey(mixed $keyValue, bool $getFreshData = false, bool $doPreFetchProcess = true): ?object
    {
        $rowObject = $this->getRowReference((object)['Code' => $keyValue], $getFreshData);
        if ($rowObject !== null && (bool)$this->preFetchRefreshScripts) {
            $bookingId = '';
            if (isset($rowObject->BookingId)) {
                $bookingId = $rowObject->BookingId;
            } else if (isset($rowObject->BookingNumber)) {
                $bookingId = $rowObject->BookingNumber;
            }
            foreach ($this->preFetchRefreshScripts as $preFetchRefreshScript) {
                $preFetchProcessScript = str_replace('$bookingIds', "'$bookingId'", $preFetchRefreshScript);
                if ($doPreFetchProcess) SAPAccessManager::getInstance()->runUpdateNativeQuery([$preFetchProcessScript]);
            }
            $rowObject = $this->getRowReference((object)['Code' => $keyValue], $getFreshData);
        }
        return $rowObject;
    }

    public function getColumnReference(string $prop, mixed $propValue, bool $includeForeignFields = false): ?ColumnDefinition
    {
        $columnDefinitions = array_values(array_filter(
            $this->columnDefinitions,
            fn ($z) => ($includeForeignFields || !in_array($propValue, $this->foreignFields)) && (($z->{$prop} === $propValue || $z->{$prop} === "_$propValue")
                || ((bool)$this->similarFields && array_key_exists($z->{$prop}, $this->similarFields)
                    && in_array($propValue, $this->similarFields[$z->{$prop}])))
        ));
        if ((bool)$columnDefinitions) return $columnDefinitions[0];
        if ($prop === 'fieldName') {
            if ((bool)($columnDefinition = $this->getSimilarColumn($propValue, $includeForeignFields))) return $columnDefinition;
        }
        return null;
    }

    private function doesColumnExist(string $fieldName, bool $includeForeignFields = false): bool
    {
        if ((bool)array_values(array_filter($this->columnDefinitions, fn ($z) => $z->fieldName === $fieldName))) return true;
        if ((bool)($columnDefinition = $this->getSimilarColumn($fieldName, $includeForeignFields))) return true;
        return false;
    }

    public function getSimilarColumn(string $fieldName, bool $includeForeignFields = false): ?ColumnDefinition
    {
        if (!(bool)$this->similarColumns) return null;
        foreach ($this->similarColumns as $similarColumn) {
            foreach ((array)$similarColumn as $tab => $field) {
                if ($field === $fieldName && get_class($this) !== $tab) {
                    $columnFieldName = $similarColumn->{get_class($this)};
                    if (!(bool)$columnFieldName) return null;
                    return $this->getColumnReference('fieldName', $columnFieldName, $includeForeignFields);
                }
            }
        }
        return null;
    }

    public function getNativeColumnEquivalent(string $fieldName): string
    {
        return PctpWindowTabHelper::getInstance($this->settings)->getNativeColumnEquivalent($fieldName);
    }

    private function preProcessSapObj(object $sapObj): object
    {
        $duplicate_keys = [];
        $tmp = [];
        foreach ($sapObj->lines as $key => $val) {
            if (is_object($val)) {
                $val = (array)$val;
            }
            if (!in_array($val, $tmp)) {
                $tmp[] = $val;
            } else {
                $duplicate_keys[] = $key;
            }
        }
        foreach ($duplicate_keys as $key) {
            unset($sapObj->lines[$key]);
        }
        $sapObj->lines = array_values($sapObj->lines);
        return $sapObj;
    }

    public function postTransaction(PctpWindowModel $model, object $sapObj, ASAPDocumentStructure $structure): mixed
    {
        $result = $this->postProcessPostingTransaction(SAPAccessManager::getInstance()->postTransaction($this->preProcessSapObj($sapObj), $structure));
        $bookingIds = [];
        if ($result->valid) {
            foreach ($result->rData as $rDataObj) {
                foreach ($rDataObj->rDataRows as $rDataRow) {
                    foreach ($rDataRow->rows as $row) {
                        foreach ($model->{$rDataRow->tab . 'Tab'}->tableRows as $tableRow) {
                            if ($row['Code'] === $tableRow->Code) {
                                $bookingIds[] = (object)['BookingId' => $tableRow->BookingId];
                                foreach ($row['props'] as $field => $value) {
                                    $tableRow->{$field} = $value;
                                }
                                break;
                            }
                        }
                    }
                }
            }
        }
        if ((bool)$bookingIds) $this->preFetchProcess($bookingIds, $this->settings->preFetchRefreshScripts);
        return $result;
    }

    private function screenFetchedRows(array $rows): array
    {
        PctpWindowTabHelper::getInstance($this->settings)->rowsFieldConstantReplacement($rows, ...$this->fieldConstants);
        PctpWindowTabHelper::getInstance($this->settings)->formatFieldValues($this, $rows);
        if (in_array(get_class($this), ['PodTab', 'BillingTab', 'TpTab'])) PctpWindowTabHelper::getInstance($this->settings)->setAttachmentsBasenames($this, $rows, false);
        return $this->postFetchProcessRows($rows);
    }

    public function initializeSapObjs(object $row): mixed
    {
        foreach ($this->sapDocumentStructureTypes as $sapDocumentStructureType) {
            if ($sapObj = $this->createSapObj($row, $sapDocumentStructureType)) {
                if (array_key_exists($sapDocumentStructureType, $this->sapObjs)) {
                    $this->sapObjs[$sapDocumentStructureType][] = $sapObj;
                } else {
                    $this->sapObjs[$sapDocumentStructureType] = [];
                    $this->sapObjs[$sapDocumentStructureType][] = $sapObj;
                }
                $row->sapDocumentStructureType = $sapDocumentStructureType;
                return $sapDocumentStructureType;
            }
        }
        return false;
    }

    private function createSapObj(object $row, string $sapDocumentStructureType): mixed
    {
        $structure = $this->settings->sapDocumentStructures->{$sapDocumentStructureType};
        foreach ($structure->fieldValidations as $field => $validationOption) {
            $regex = $validationOption['regex'];
            if (!preg_match("/$regex/", $row->{$field})) {
                return false;
            }
        }
        $sapObj = [];
        $sapObj['Code'] = $row->Code;
        $sapObj['podNum'] = $row->PODNum;
        $headers = [];
        foreach ($structure->headers as $key => $value) {
            if ((bool)$value) {
                $headers[$key] = $row->{$value};
            } else {
                $headers[$key] = $structure->defaults[$key];
            }
        }
        $sapObj['headers'] = $headers;
        $line = [];
        foreach ($structure->lines as $key => $value) {
            if ($value) {
                $line[$key] = $row->{$value};
            } else {
                $line[$key] = $structure->defaults[$key];
            }
        }
        $sapObj['lines'] = [$line];
        $sapObj = json_decode(json_encode($sapObj));
        if ($this->validateSapObj($sapObj)) {
            return (object) ['type' => $sapDocumentStructureType, 'data' => $sapObj];
        }
        return null;
    }

    private function validateSapObj(object $sapObj): bool
    {
        if (!$this->isValidData($sapObj->Code)) return false;
        foreach ((array)$sapObj->headers as $key => $value) {
            if (!$this->isValidData($value)) return false;
        }
        foreach ((array)$sapObj->lines as $line) {
            foreach ($line as $key => $value) {
                if (!$this->isValidData($value)) return false;
            }
        }
        return true;
    }

    public function isValidData(mixed $data): bool
    {
        if (!isset($data) || is_null($data) || $data === '') return false;
        return true;
    }

    public function getSapObjReference(string $rowCode, SAPDocumentStructureType $structureType): object
    {
        if (array_key_exists($structureType->name(), $this->sapObjs)) {
            if ((bool)$fetchedSapObjs = array_values(array_filter($this->sapObjs[$structureType->name()], fn ($z) => $z->data->Code === $rowCode))) {
                return $fetchedSapObjs[0]->data;
            }
            return null;
        }
    }

    public function removeSapObj(string $rowCode, SAPDocumentStructureType $structureType)
    {
        if (array_key_exists($structureType->name(), $this->sapObjs)) {
            $this->sapObjs[$structureType->name()] = array_values(array_filter($this->sapObjs[$structureType->name()], fn ($z) => $z->data->Code !== $rowCode));
        }
    }

    private function postUpdateProcess(PctpWindowModel &$model, array $rows, bool $doPreFetchProcess = true)
    {
        $bookingIds = [];
        foreach ($rows as $row) {
            foreach ($this->tableRows as $tableRow) {
                if ($row->Code === $tableRow->Code) {
                    $bookingIds[] = $row;
                    foreach ($row->props as $field => $value) {
                        $tableRow->{$field} = $value;
                    }
                    break;
                }
            }
        }
        if ($doPreFetchProcess) $this->preFetchProcess($bookingIds, $this->settings->preFetchRefreshScripts);
        $this->postUpdateProcessRows($model, $rows);
    }

    public function processRelatedUpdates(PctpWindowModel &$model, array $rows): array
    {
        $relatedUpdateTabs = [];
        foreach ($this->columnValidations as $targetField => $fieldEvent) {
            foreach ($rows as $row) {
                foreach ((array)$row->props as $field => $value) {
                    $foundRelated = false;
                    if (isset($row->relatedProps)) {
                        $foundRelated = array_values(array_filter($row->relatedProps, fn ($z) => $z->subject === $targetField));
                    }
                    if ($field === $targetField || (bool)$foundRelated) {
                        foreach ($fieldEvent->events as $eventType => $eventObjs) {
                            foreach ($eventObjs as $eventObj) {
                                if (in_array($value, $eventObj->values) || count($eventObj->values) === 0) {
                                    if (isset($eventObj->relatedUpdates)) {
                                        $relatedTabName = $eventObj->relatedUpdates[0]['tab'];
                                        $props = [];
                                        foreach ($eventObj->relatedUpdates[0]['fields'] as $otherField => $otherValue) {
                                            if ($otherValue === 'self') {
                                                if ($field !== $targetField && (bool)$foundRelated) {
                                                    $props[$otherField] = $foundRelated[0]->value;
                                                } else {
                                                    $props[$otherField] = $value;
                                                }
                                            } else {
                                                $props[$otherField] = $otherValue;
                                            }
                                        }
                                        $relatedTable = array_values(array_filter($this->relatedTables, fn ($z) => $z->tab === $relatedTabName . 'Tab'))[0];
                                        $ownFieldValue = $this->getRowReferenceByKey($row->Code, false, false)->{$relatedTable->ownField};
                                        $relatedUpdateRow = null;
                                        if ($relatedTable->foreignField === 'Code') {
                                            $relatedUpdateRow = (object)[
                                                'Code' => $ownFieldValue,
                                                'props' => (object)$props,
                                            ];
                                        } else {
                                            $foreignRow = $model->{$relatedTabName . 'Tab'}->getFirstRowReferenceByKeyValue($relatedTable->foreignField, $ownFieldValue);
                                            if (is_null($foreignRow)) continue;
                                            $foreignCodeValue = $foreignRow->Code;
                                            if (!is_null($foreignCodeValue)) {
                                                $relatedUpdateRow = (object)[
                                                    'Code' => $foreignCodeValue,
                                                    'props' => (object)$props,
                                                    'BookingId' => $row->BookingId
                                                ];
                                            }
                                        }
                                        if (is_null($relatedUpdateRow)) continue;
                                        if ($model->{$relatedTable->tab}->updateRows($model, [$relatedUpdateRow], false)) {
                                            $relatedUpdateTab = [];
                                            $relatedUpdateTab['tab'] = $relatedTabName;
                                            $relatedUpdateTab['rows'] = [$relatedUpdateRow];
                                            $relatedUpdateTabs[] = $relatedUpdateTab;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return $relatedUpdateTabs;
    }

    public function persistTableRow(object $tableRow): bool
    {
        return SAPAccessManager::getInstance()->directInsertRow($this->tableName, $tableRow, $this);
    }

    public function getUploadedAttachment(bool $doRefresh = false): object
    {
        if (!$doRefresh && ((bool)((array)$this->uploadedAttachment))) return $this->uploadedAttachment;
        $uploadedAttachment = [];
        foreach ($this->tableRows as $row) {
            foreach ((array)$row as $key => $value) {
                if ($key === 'Attachment') {
                    $tabName = strtolower(str_replace('Tab', '', get_class($this)));
                    $uploadedAttachment[$tabName . $row->Code] = [
                        'attachment' => $value === null ? '' : $value,
                        'upload' => null,
                        'uploaded' => 'no',
                        'removed' => 'no'
                    ];
                }
            }
        }
        $this->uploadedAttachment = (object)$uploadedAttachment;
        return $this->uploadedAttachment;
    }

    public function getFirstRowReferenceByKeyValue(string $field, mixed $value): ?object
    {
        $column = PctpWindowTabHelper::getInstance($this->settings)->getFormattedNativeColumn($this->getColumnReference('fieldName', $field), false, $this->settings->defaultSQLMainTableAlias);
        return $this->getRowReferenceByScript("WHERE $column = '$value'");
    }

    private function getRowReferenceByScript(string $whereClause): ?object
    {
        $result = SAPAccessManager::getInstance()->getRows($this->script . ' ' . $whereClause);
        if ((bool)$result && isset($result[0])) {
            $newRow = [];
            foreach ((array)$result[0] as $key => $value) {
                $key = str_replace('U_', '', $key);
                if ((bool)$this->columnsNeedUtf8Conversion && count(array_filter($this->columnsNeedUtf8Conversion, fn ($a) => $a === $key))) {
                    $newRow[$key] = utf8_encode($value);
                } else {
                    $newRow[$key] = $value;
                }
            }
            return (object)$newRow;
        }
        return null;
    }

    public function groupFieldUpdate(PctpWindowHeader $header, object $props, ?array $excludeKeys)
    {
        $filterClause = '';
        $filterClauseChunks = $this->createFilterClauseChunks($header);
        if ((bool)$this->defaultFetchFilterClause) $filterClauseChunks[] = $this->defaultFetchFilterClause;
        if ((bool)$filterClauseChunks) {
            $filterClause = ' WHERE ' . join(' AND ', $filterClauseChunks);
        }
        $fieldProps = [];
        foreach ((array)$props as $field => $value) {
            $decoratedValue = '';
            $columnType = !is_null($this->getColumnReference('fieldName', $field)) ?
                $this->getColumnReference('fieldName', $field)->columnType
                : null;
            switch ($columnType) {
                case null:
                    break;
                case ColumnType::DATE:
                    $decoratedValue = (bool)$value ? "CONVERT(date, '$value')" : "NULL";
                    break;
                case ColumnType::ALPHANUMERIC:
                case ColumnType::TEXT:
                case ColumnType::TIME:
                    $decoratedValue = "'$value'";
                    break;
                default:
                    $decoratedValue = $value === '' ? "NULL" : $value;
                    break;
            }
            if ((bool)$decoratedValue) $fieldProps[] = $this->getNativeColumnEquivalent($field) . ' = ' . $decoratedValue;
        }
        if (!(bool)$fieldProps) return false;
        $propsStr = join(', ', $fieldProps);
        $excludeKeysStr = !(bool)$excludeKeys ? '' : "AND $this->key NOT IN (" . join(', ', $excludeKeys) . ')';
        $result = SAPAccessManager::getInstance()->runUpdateNativeQuery(
            ["   UPDATE $this->tableName 
            SET $propsStr
            $filterClause
            $excludeKeysStr
        "]
        );
        if ($result) {
            $bookingIds = $this->getFilteredBookingIds(false, $filterClause);
            if ((bool)$bookingIds) $this->preFetchProcess($bookingIds, $this->settings->preFetchRefreshScripts);
            return $result;
        }
        return $result;
    }

    public function getTableRowsData(bool $isFreshFromDB = false, object $dataTableSetting = null, bool $disableUtf8Encoding = false): array
    {
        $arrayOfDataArray = [];
        if ($isFreshFromDB) {
            $resultTableRows = $this->fetchRows(
                $this->findHeader,
                $dataTableSetting,
                false,
                false
            );
            if (!(bool)$resultTableRows) return $arrayOfDataArray;
            // return $resultTableRows;
            foreach ($resultTableRows as $tableRow) {
                $dataArray = [];
                foreach ($this->columnDefinitions as $columnDefinition) {
                    if ($disableUtf8Encoding) {
                        $dataArray[] = $tableRow->{preg_replace('/^_/', '', $columnDefinition->fieldName)};
                    } else {
                        $dataArray[] = utf8_encode($tableRow->{preg_replace('/^_/', '', $columnDefinition->fieldName)});
                    }
                }
                $arrayOfDataArray[] = $dataArray;
            }
        } else {
            if (!(bool)$this->tableRows) return $arrayOfDataArray;
            foreach ($this->tableRows as $tableRow) {
                $dataArray = [];
                foreach ($this->columnDefinitions as $columnDefinition) {
                    if ($disableUtf8Encoding) {
                        $dataArray[] = $tableRow->{preg_replace('/^_/', '', $columnDefinition->fieldName)};
                    } else {
                        $dataArray[] = utf8_encode($tableRow->{preg_replace('/^_/', '', $columnDefinition->fieldName)});
                    }
                }
                $arrayOfDataArray[] = $dataArray;
            }
        }
        return $arrayOfDataArray;
    }

    public function preFetchProcess(array $bookingIds, array $allPreFetchRefreshScripts = [])
    {
        if (!(bool)$allPreFetchRefreshScripts) $allPreFetchRefreshScripts = $this->preFetchRefreshScripts;
        foreach ($allPreFetchRefreshScripts as $preFetchRefreshScript) {
            $bookingIdsStr = "'" . join("','", array_map(fn ($z) => $z->BookingId, $bookingIds)) . "'";
            $preFetchProcessScript = str_replace(['$bookingIds', '$serial'], [$bookingIdsStr, session_id()], $preFetchRefreshScript);
            SAPAccessManager::getInstance()->runUpdateNativeQuery([$preFetchProcessScript]);
        }
    }
    protected abstract function postFetchProcessRows(array $rows): array;
    protected abstract function postProcessPostingTransaction(object $args): mixed;
    protected abstract function preUpdateProcessRows(PctpWindowModel &$model, array $rows): array;
    protected abstract function postUpdateProcessRows(PctpWindowModel &$model, array $rows);
}
