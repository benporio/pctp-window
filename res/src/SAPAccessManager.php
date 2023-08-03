<?php

require_once __DIR__.'/../inc/restriction.php';

final class SAPAccessManager extends DataAccessProvider
{
    private const ARG = ARG;
    private const DB_SERVER_TYPE = DB_SERVER_TYPE;
    private const SERVER = SERVER;
    private const USE_TRUSTED = USE_TRUSTED;
    private const DB_USER_NAME = DB_USER_NAME;
    private const DB_PASSWORD = DB_PASSWORD;
    private const USER_NAME = USER_NAME;
    private const PASSWORD = PASSWORD;
    private const LICENSE_SERVER = LICENSE_SERVER;

    private static SAPAccessManager $instance;
    private function __construct(){}
    public static function getInstance() {
        if (isset(self::$instance) && self::$instance !== null) {
            return self::$instance;
        }
        self::$instance = new SAPAccessManager();
        return self::$instance;
    }

    private static function getSAPCompanyObject(): object
    {
        $sapCompanyObj = new COM(self::ARG);
        $sapCompanyObj->DbServerType = self::DB_SERVER_TYPE;
        $sapCompanyObj->server = self::SERVER;
        $sapCompanyObj->UseTrusted = self::USE_TRUSTED;
        $sapCompanyObj->DBusername = self::DB_USER_NAME;
        $sapCompanyObj->DBpassword = self::DB_PASSWORD;
        $sapCompanyObj->CompanyDB = $_SESSION['MSSQL_DB'];
        $sapCompanyObj->username = self::USER_NAME;
        $sapCompanyObj->password = self::PASSWORD;
        $sapCompanyObj->LicenseServer = self::LICENSE_SERVER;
        return $sapCompanyObj;
    }

    public function sendMessage(string $toUserCode, string $subjectText, string $messageText) {
        $sapCompanyObj = null;
        try {
            $sapCompanyObj = self::getSAPCompanyObject();
        } catch (\Exception $e) {
            throw $e;
        }
        if ($sapCompanyObj !== null && $sapCompanyObj->Connect != 0) {
            return (object) [
                'valid' => false,
                'message' => $sapCompanyObj->GetLastErrorDescription
            ];
        } else {
            $message = $sapCompanyObj->GetBusinessObject(81);
            $message->Subject = $subjectText;
            $message->MessageText = $messageText;
            $message->Recipients->Add();
            $message->Recipients->SetCurrentLine(0);
            $message->Recipients->SendInternal = 1;
            $message->Recipients->UserCode = $toUserCode;
            $message->Recipients->UserType = 12;
            $message->Add();
        }
    }

    public function postTransaction(object $transaction, ASAPDocumentStructure $structure): mixed 
    {
        $sapCompanyObj = null;
        try {
            $sapCompanyObj = self::getSAPCompanyObject();
        } catch (\Exception $e) {
            throw $e;
        }
        if ($sapCompanyObj !== null && $sapCompanyObj->Connect != 0) {
            return (object) [
                'valid' => false,
                'message' => $sapCompanyObj->GetLastErrorDescription
            ];
        } else {
            $sapCompanyObj->StartTransaction();
            try {
                $sapDocument = $sapCompanyObj->GetBusinessObject($structure->objectType->value);
                foreach (array_keys($structure->headers) as $key) {
                    $sapDocument->{$key} = trim($this->formatValue($transaction->headers->{$key}, $structure->getColumnType($key)));
                }
                $baseLineIndex = 0;
                $baseEntryBuff = '';
                foreach ($transaction->lines as $line) {
                    if (isset($line->BaseEntry)) {
                        if ($baseEntryBuff === '') {
                            $baseEntryBuff = $line->BaseEntry;
                        } else if ($baseEntryBuff !== $line->BaseEntry) {
                            $baseEntryBuff = $line->BaseEntry;
                            $baseLineIndex = 0;
                        }
                    }
                    if (isset($line->overrideLine)) {
                        foreach (array_keys((array)$line->overrideLine) as $key) {
                            if ($key === 'BaseLine') {
                                $sapDocument->Lines->{$key} = $baseLineIndex;
                                $baseLineIndex++;
                            } else {
                                if (isset($structure->fieldPreProcessing) && isset($structure->fieldPreProcessing[$key])) {
                                    $preProcessor = $structure->fieldPreProcessing[$key];
                                    $preProcessedValue = $preProcessor(trim($line->{$key}));
                                    $sapDocument->Lines->{$key} = $preProcessedValue;
                                } else {
                                    $sapDocument->Lines->{$key} = trim($line->{$key});
                                }
                            }
                        }
                    } else {
                        foreach (array_keys($structure->lines) as $key) {
                            if ($key === 'BaseLine') {
                                $sapDocument->Lines->{$key} = $baseLineIndex;
                                $baseLineIndex++;
                            } else {
                                if (isset($structure->fieldPreProcessing) && isset($structure->fieldPreProcessing[$key])) {
                                    $preProcessor = $structure->fieldPreProcessing[$key];
                                    $preProcessedValue = $preProcessor(trim($line->{$key}));
                                    $sapDocument->Lines->{$key} = $preProcessedValue;
                                } else {
                                    $sapDocument->Lines->{$key} = trim($line->{$key});
                                }
                            }
                        }
                    }
                    $sapDocument->Lines->Add();
                }
                $retval = $sapDocument->Add();
                if ($retval != 0) {
                    if ($sapCompanyObj->Connected && $sapCompanyObj->InTransaction)
                        $sapCompanyObj->EndTransaction(1);
                    return (object) [
                        'valid' => false,
                        'message' => $sapCompanyObj->GetLastErrorDescription
                    ];
                }
                $docNum = '';
                $sapCompanyObj->GetNewObjectCode($docNum);
                $sapCompanyObj->EndTransaction(0);
                return (object) [
                    'valid' => true,
                    'message' => 'Operation completed successfully - '.$docNum,
                    'docNum' => $docNum,
                    'sapObj' => $transaction,
                    'structure' => $structure
                ];
            } catch (\Exception $e) {
                if ($sapCompanyObj->Connected && $sapCompanyObj->InTransaction) {
                    $sapCompanyObj->EndTransaction(1);
                }
                throw $e;
            }
        }
    }

    private function formatValue(mixed $rawValue, ?ColumnType $columnType): mixed
    {
        switch ($columnType) {
            case ColumnType::DATE:
                return date('Y-m-d', strtotime($rawValue));
            case ColumnType::INT:
                return intval($rawValue);
            case ColumnType::FLOAT:
                return floatval($rawValue);
            default:
                return $rawValue;
        }
    }

    public function getRows(string $query, IArrayProcessor $preProcessObjRowArrResult = null): mixed
    {
        $objRowArrResult = $this->getQueryResultRowObj($query);
        if ((bool)$preProcessObjRowArrResult) {
            $preProcessObjRowArrResult->process($objRowArrResult);
        }
        return $objRowArrResult;
    }

    public function runUpdateNativeQuery(array $queries): mixed
    {
        return $this->update(join('; ', $queries));
    }

    public function directUpdateTable(string $table, array $rows, APctpWindowTab $caller): bool
    {
        $queries = [];
        foreach ($rows as $row) {
            $props = [];
            foreach ($row->props as $key => $value) {
                if (get_class($caller) === 'BillingTab' 
                    && $key === 'BillingStatus' 
                    && in_array($value, ['OnHoldbyBilling', 'NotChargeabletoclient', 'Lostparcels', 'ExceedBillingDeadline'])
                    && isset($row->old->BillingStatus)) {
                    $bookingId = isset($row->BookingId) ? $row->BookingId : null;
                    if ($bookingId === null) {
                        $bookingId = trim($caller->getRowReferenceByKey($row->Code)->BookingId);
                    }
                    $changeByUser = strtoupper($_SESSION['SESS_NAME']);
                    $oldValue = (bool)$row->old->BillingStatus ? $row->old->BillingStatus : 'none';
                    $this->sendMessage(
                        PctpWindowSettings::getInstance()->notificationReceipientUserCode, 
                        "$bookingId Billing Status changed", 
                        "$changeByUser has changed the billing status of $bookingId from $oldValue to $value."
                    );
                }
                $decoratedValue = '';
                $columnType = !is_null($caller->getColumnReference('fieldName', $key)) ? 
                    $caller->getColumnReference('fieldName', $key)->columnType
                    : null;
                if ($columnType !== null && in_array($columnType, [ColumnType::ALPHANUMERIC, ColumnType::TEXT]) 
                    && strlen($value) !== strlen(utf8_decode($value))) {
                    $value = utf8_decode($value);
                }
                switch ($columnType) {
                    case null:
                        break;
                    case ColumnType::DATE:
                        $decoratedValue = (bool)$value ? "CONVERT(date, '$value')" : "NULL";
                        break;
                    case ColumnType::ALPHANUMERIC:
                    case ColumnType::TEXT:
                    case ColumnType::TIME:
                        $value = $this->validateStringArgForQuery($value);
                        $decoratedValue = "'$value'";
                        break;
                    default:
                        $decoratedValue = $value === '' ? "NULL" : $value;
                        break;
                }
                if ((bool)$decoratedValue || ($decoratedValue == 0 && $columnType === ColumnType::FLOAT)) $props[] = $caller->getNativeColumnEquivalent($key).' = '.$decoratedValue;
            }
            if ((bool)$props) {
                $propsStr = join(', ', $props);
                $keyColumn = '';
                if (isset($caller->updateFieldAlias) && count($caller->updateFieldAlias) && isset($caller->updateFieldAlias[$caller->key])) {
                    $keyColumn = $caller->getNativeColumnEquivalent($caller->updateFieldAlias[$caller->key]);
                } else {
                    $keyColumn = $caller->getNativeColumnEquivalent($caller->key);
                }
                $queries[] = "UPDATE $table SET $propsStr WHERE $keyColumn = '".$row->{$caller->key}."'";
            }
        }
        if ((bool)$queries) {
            $results = $this->directUpdateRelatedTable($caller, $queries, $rows, ...$caller->relatedTables);
            $queries = $results['queries'];
            $relatedQueries = $results['relatedQueries'];
            $result = $this->update(join('; ', $queries));
            if ($result) {
                $insertValues = [];
                foreach ($rows as $row) {
                    if (!isset($row->BookingId)) continue;
                    $modRow = json_decode(json_encode($row));
                    $modRow->{'new'} = $modRow->props;
                    unset($modRow->props);
                    if ((bool)$relatedQueries) $modRow->{'relatedNativeQuery'} = $relatedQueries[$modRow->BookingId];
                    $jsonData = json_encode($modRow);
                    $jsonData = $this->validateStringArgForQuery($jsonData);
                    $insertValues[] = " ('UPDATE', '$modRow->BookingId', '$jsonData') ";
                }
                if ((bool)$insertValues) {
                    $insertValuesStr = join(',', $insertValues);
                    $this->insert(
                    "   INSERT INTO PCTP_WINDOW_JSON_LOG
                        (event_type, ref_id, json_data)
                        VALUES
                        $insertValuesStr;
                    ");
                }
            }
            return $result;
        }
        return false;
    }

    private function directUpdateRelatedTable(APctpWindowTab $caller, array $queries, array $rows, RelatedTable ...$relatedTables): array {
        $model = PctpWindowFactory::getObject('PctpWindowController', $_SESSION)->model;
        $relatedQueries = [];
        if ((bool)$relatedTables) {
            foreach ($relatedTables as $relatedTable) {
                $tab = $model->{$relatedTable->tab};
                foreach ($rows as $row) {
                    $referenceRow = $caller->getRowReference($row);
                    if (!(bool)$referenceRow->{$relatedTable->ownField}) continue;
                    $props = [];
                    foreach ($row->props as $key => $value) {
                        $columnDefinition = null;
                        if ((bool)$caller->foreignFields && !in_array($key, $caller->foreignFields)) {
                            if ((bool)$tab->notSameColumns 
                                && isset($tab->notSameColumns[get_class($caller)])
                                && in_array($key, $tab->notSameColumns[get_class($caller)])) {
                                $columnDefinition = $tab->getSimilarColumn($key);
                            } else {
                                $columnDefinition = $tab->getColumnReference('fieldName', $key);
                            }
                        }
                        if ($columnDefinition !== null && !in_array($key, $tab->foreignFields)) {
                            $decoratedValue = '';
                            switch ($columnDefinition->columnType) {
                                case ColumnType::DATE:
                                    $decoratedValue = (bool)$value ? "CONVERT(date, '$value')" : "''";
                                    break;
                                case ColumnType::ALPHANUMERIC:
                                case ColumnType::TEXT:
                                case ColumnType::TIME:
                                    $value = $this->validateStringArgForQuery($value);
                                    $decoratedValue = "'$value'";
                                    break;
                                default:
                                    $decoratedValue = $value === '' ? "null" : $value;
                                    break;
                            }
                            $props[] = $tab->getNativeColumnEquivalent($columnDefinition->fieldName).' = '.$decoratedValue;
                        }
                    }
                    if ((bool)$props) {
                        $propsStr = join(', ', $props);
                        $foreignColumn = $tab->getNativeColumnEquivalent($relatedTable->foreignField);
                        $table = $model->getSettings()->tabTables[$relatedTable->tab];
                        $query = "UPDATE $table SET $propsStr WHERE $foreignColumn = '".$referenceRow->{$relatedTable->ownField}."'";
                        $queries[] = $query;
                        $relatedQueries[$row->BookingId] = $query;
                    }
                }
            }
        }
        return ['queries' => $queries, 'relatedQueries' => $relatedQueries];
    }

    public function directInsertRow(string $table, object $row, APctpWindowTab $caller): bool
    {
        $columns = [];
        $values = [];
        foreach ((array)$row as $field => $value) {
            $columns[] = $caller->getNativeColumnEquivalent($field);
            $decoratedValue = '';
            switch ($caller->getColumnReference('fieldName', $field)->columnType) {
                case ColumnType::DATE:
                    $decoratedValue = (bool)$value ? "CONVERT(date, '$value')" : "''";
                    break;
                case ColumnType::ALPHANUMERIC:
                case ColumnType::TEXT:
                    $value = $this->validateStringArgForQuery($value);
                    $decoratedValue = "'$value'";
                    break;
                default:
                    $decoratedValue = is_null($value) ? 'null' : $value;
                    break;
            }
            $values[] = $decoratedValue;
        }
        if ((bool)$columns) {
            $columnsStr = join(', ', $columns);
            $valuesStr = join(', ', $values);
            return $this->update("INSERT INTO $table ($columnsStr) VALUES ($valuesStr)");
        }
        return false;
    }

    public function validateStringArgForQuery(string $arg): string
    {
        try {
            return $this->validateStringArg($arg);
        } catch (\Exception $e) {
            throw $e;
        }
    }
}