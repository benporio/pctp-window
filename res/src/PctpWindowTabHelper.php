<?php

final class PctpWindowTabHelper
{
    private static PctpWindowTabHelper $instance;
    private function __construct()
    {
    }
    private static PctpWindowSettings $settings;
    public static function getInstance(PctpWindowSettings $settings)
    {
        if (isset(self::$instance) && self::$instance !== null) {
            return self::$instance;
        }
        self::$instance = new PctpWindowTabHelper();
        self::$settings = $settings;
        return self::$instance;
    }

    final public function rowsFieldConstantReplacement(array &$rows, FieldConstant ...$fieldConstants)
    {
        if (!(bool)$fieldConstants) return;
        foreach ($fieldConstants as $fieldConstant) {
            foreach ($rows as $row) {
                foreach ($row as $field => $value) {
                    if ($field === $fieldConstant->fieldName) {
                        $constant = self::$settings->constants[$fieldConstant->constantName];
                        $rowConstant = array_values(array_filter($constant, fn ($z) => preg_replace('/\D+/', '', $z->Code) === $row->Code));
                        if ((bool)$rowConstant && !is_null($rowConstant[0]->{$fieldConstant->constantName})) {
                            $row->{$field} = utf8_encode($rowConstant[0]->{$fieldConstant->constantName});
                        }
                    }
                }
            }
        }
    }

    final public function getNativeColumnEquivalent(string $fieldName): string
    {
        if (self::$settings->isImmutableFieldName($fieldName)) return $fieldName;
        return self::$settings->getSQLColumnFormat(preg_replace('/^_/', '', $fieldName));
    }

    final public function getFormattedNativeColumn(?ColumnDefinition $columnDefinition, bool $createAliasFieldName = true, string $tableAlias = ''): string
    {
        if (is_null($columnDefinition)) return '';
        if (self::$settings->isImmutableFieldName($columnDefinition->fieldName)) return ((bool)$tableAlias ? "$tableAlias." : '') . $columnDefinition->fieldName;
        if ($columnDefinition->columnType === ColumnType::TEXT) {
            $column = ((bool)$tableAlias ? "$tableAlias." : '') . self::$settings->getSQLColumnFormat($columnDefinition->fieldName);
            return $this->formatTextColumn($column) . ($createAliasFieldName ? ' AS ' . ((bool)$tableAlias ? "$tableAlias." : '') . $column : '');
        }
        return ((bool)$tableAlias ? "$tableAlias." : '') . $this->getNativeColumnEquivalent($columnDefinition->fieldName);
    }

    private function formatTextColumn(string $column)
    {
        return "CAST( $column as nvarchar(max))";
    }

    public function formatFieldValues(APctpWindowTab $caller, array &$rows)
    {
        foreach ($rows as $row) {
            $this->formatRowFieldValues($caller, $row);
        }
    }

    public function formatRowFieldValues(APctpWindowTab $caller, object &$row)
    {
        foreach ($row as $field => $value) {
            $columnDefinition = $caller->getColumnReference('fieldName', $field, true);
            if (
                $columnDefinition !== null && in_array($columnDefinition->columnType, [ColumnType::ALPHANUMERIC, ColumnType::TEXT])
                && strlen($value) !== strlen(utf8_encode($value))
            ) {
                $row->{$field} = utf8_encode($value);
            }
            if (is_null($columnDefinition)) $columnDefinition = $caller->getColumnReference('fieldName', "_$field");
            if (is_null($columnDefinition)) continue;
            switch ($columnDefinition->columnType) {
                case ColumnType::DATE:
                    if ($caller->isValidData($value)) $row->{$field} = $this->SAPDateFormatter($value);
                    break;
                case ColumnType::INT:
                    if ($caller->isValidData($value)) $row->{$field} = intval($value);
                    break;
                case ColumnType::FLOAT:
                    if ($caller->isValidData($value)) $row->{$field} = number_format(floatval($value), self::$settings->constants['SAPPriceDecimal']);
                    break;
                default:
                    # code...
                    break;
            }
        }
    }

    public function SAPDateFormatter(string $dateLiteral): string
    {
        if (is_null($dateLiteral) || !(bool)$dateLiteral) return '';
        $sep = self::$settings->constants['DateSeparator'];
        $dateFormats = array(
            join($sep, ['d', 'm', 'y']),
            join($sep, ['d', 'm', 'Y']),
            join($sep, ['m', 'd', 'y']),
            join($sep, ['m', 'd', 'Y']),
            join($sep, ['Y', 'm', 'd']),
            join($sep, ['d', 'F', 'Y']),
            join($sep, ['y', 'm', 'd']),
        );
        return date($dateFormats[intval(self::$settings->constants['SAPDateFormat'])], strtotime($dateLiteral));
    }

    public function SQLDateFormatter(string $dateLiteral): string
    {
        if (is_null($dateLiteral) || !(bool)$dateLiteral) return '';
        $dateElements = explode('.', $dateLiteral);
        $rearrangedDateLiteral = '';
        switch (intval(self::$settings->constants['SAPDateFormat'])) {
            case 2:
            case 3:
                $rearrangedDateLiteral = $dateElements[1] . '.' . $dateElements[0] . '.' . $dateElements[2];
                return date('Y-m-d', strtotime($rearrangedDateLiteral));
            case 4:
            case 6:
                $rearrangedDateLiteral = $dateElements[2] . '.' . $dateElements[1] . '.' . $dateElements[0];
                return date('Y-m-d', strtotime($rearrangedDateLiteral));
            default:
                return $dateLiteral;
        }
    }

    public function createUploadedAttachmentObj(array $tableRows, string $tabName): object
    {
        $uploadedAttachment = [];
        foreach ($tableRows as $row) {
            foreach ((array)$row as $key => $value) {
                if ($key === 'Attachment') {
                    $uploadedAttachment[$tabName . $row->Code] = [
                        'attachment' => $value === null ? '' : $value,
                        'upload' => null,
                        'uploaded' => 'no',
                        'removed' => 'no'
                    ];
                }
            }
        }
        return (object)$uploadedAttachment;
    }

    public function countFetchTableRows(APctpWindowTab $caller, string $tableName, array $filterClauseChunks): int
    {
        $filterClause = '';
        if ((bool)$caller->defaultFetchFilterClause) $filterClauseChunks[] = $caller->defaultFetchFilterClause;
        if ((bool)$filterClauseChunks) {
            $filterClauseChunks = array_map(
                fn ($z) => preg_replace(
                    self::$settings->columnValidRegexPrefix . self::$settings->defaultSQLColumnPrefix . '/i',
                    self::$settings->defaultSQLMainTableAlias . '.' . self::$settings->defaultSQLColumnPrefix,
                    $z
                ),
                $filterClauseChunks
            );
            $filterClause = ' WHERE ' . join(' AND ', $filterClauseChunks);
        }
        // $script = preg_replace('/--REMOVE_WHEN_COUNTING[\s\S]+--REMOVE_WHEN_COUNTING/', '', $caller->script);
        $script = preg_replace('/--COLUMNS[\s\S]+--COLUMNS/', 'COUNT(*) AS NoOfRows', $caller->extractScript !== '' ? $caller->extractScript : $caller->script);
        if ($caller->extractScript !== '') {
            if (str_contains($filterClause, 'billing.')) $filterClause = str_replace('billing.', ' BE.', $filterClause);
            if (str_contains($filterClause, 'BE.') || str_contains($filterClause, 'TF.')) {
                $script = str_replace('_EXTRACT', '_EXTRACT X', $script);
                $caller->manipulateJoinTablesInExtract($filterClause, $script);
                $filterClause = str_replace(['T0.', 'pod.'], ' X.', $filterClause);
            } else {
                $filterClause = preg_replace('/\s[A-Za-z0-9]+\./', ' ', $filterClause);
            }
        }
        if ($_SERVER['REMOTE_ADDR'] === '::1') file_put_contents(__DIR__ . '/../sql/tmp/count.sql', "$script \n$filterClause");
        $count = SAPAccessManager::getInstance()->getRows(
            "   $script
            $filterClause
        "
        )[0]->NoOfRows;
        return $count;
    }

    public function setAttachmentsBasenames(APctpWindowTab &$caller, array &$rows, bool $overWriteRealAttachment = true, string $tabKey = 'Code')
    {
        $realAttachment = [];
        foreach ($rows as $row) {
            $attachment = [];
            foreach ($row as $key => $value) {
                if ($key === 'Attachment') {
                    if (!isset($row->{$tabKey})) continue;
                    $attachment['Code'] = $row->{$tabKey};
                    if ((bool)$value) {
                        $basename = basename($value);
                        $row->{$key} = $basename;
                        $attachment['realAttachmentPath'] = str_replace($basename, '', $value);
                    }
                }
            }
            if (count($attachment) > 1) $realAttachment[] = (object)$attachment;
        }
        if ($overWriteRealAttachment) $caller->realAttachment = $realAttachment;
    }
}
