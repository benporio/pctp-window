<?php

require_once __DIR__.'/../inc/restriction.php';

abstract class DataAccessProvider
{
    private const MSSQL_SERVER = MSSQL_SERVER;
    private const MSSQL_USER = MSSQL_USER;
    private const MSSQL_PASSWORD = MSSQL_PASSWORD;
    private const MSSQL_DB = MSSQL_DB;

    private static function getConnection(): mixed
    {
        try {
            $connection = odbc_connect(
                "Driver={SQL Server Native Client 11.0};Server=".self::MSSQL_SERVER.";", 
                self::MSSQL_USER,
                self::MSSQL_PASSWORD
            ) or die('Could not open database!');
            if($connection) {
                return $connection;
            }
        } catch (\Exception $e) {
            throw $e;
        }
    }

    private static function closeConnection(mixed $connection)
    {
        try {
            odbc_close($connection);
        } catch (\Exception $e) {
            throw $e;
        }
    }

    private function getDateTimeNow(): string {
        $tz = 'Asia/Manila';
        $timestamp = time();
        $dt = new DateTime("now", new DateTimeZone($tz));
        $dt->setTimestamp($timestamp);
        return $dt->format('Y-m-d h:i:sa');
    }

    final protected function getQueryResultRowObj(string $query): mixed
    {
        try {
            $MSSQL_CONN = self::getConnection();
            $DB = self::MSSQL_DB;
            $objRowArrResult = array();
            $currentDateTime = $this->getDateTimeNow();
            if ($_SERVER['REMOTE_ADDR'] === '::1') file_put_contents(__DIR__.'/../sql/tmp/fetch.sql', "-- Executed on $currentDateTime \n$query");
            $qry = odbc_exec($MSSQL_CONN, "USE [$DB]; $query;");
            while ($objRowArrResult[] = odbc_fetch_object($qry)){}
            unset($objRowArrResult[count($objRowArrResult) - 1]);
            odbc_free_result($qry);
            self::closeConnection($MSSQL_CONN);
            return $objRowArrResult;
        } catch (\Exception $e) {
            $strErr = strval($e);
            $currentDateTime = $this->getDateTimeNow();
            if ($_SERVER['REMOTE_ADDR'] === '::1') file_put_contents(__DIR__.'/../sql/tmp/error.sql', "-- Executed on $currentDateTime \n$query \n-- $currentDateTime  $strErr");
            throw $e;
        }
    }

    final protected function update(string $query): bool
    {
        try {
            $MSSQL_CONN = self::getConnection();
            $DB = self::MSSQL_DB;
            odbc_autocommit($MSSQL_CONN, FALSE);
            $currentDateTime = $this->getDateTimeNow();
            if ($_SERVER['REMOTE_ADDR'] === '::1') file_put_contents(__DIR__.'/../sql/tmp/update.sql', "-- Executed on $currentDateTime \n$query");
            $qry = odbc_exec($MSSQL_CONN, "USE [$DB]; $query;");
            $result = false;
            if (!odbc_error()) {
                odbc_commit($MSSQL_CONN);
                $result = true;
            } else {
                odbc_rollback($MSSQL_CONN);
                $strErr = odbc_errormsg($MSSQL_CONN);
                $currentDateTime = $this->getDateTimeNow();
                if ($_SERVER['REMOTE_ADDR'] === '::1') file_put_contents(__DIR__.'/../sql/tmp/error.sql', "-- Executed on $currentDateTime \n$query \n-- $currentDateTime  $strErr");
                $result = false;
            }
            odbc_free_result($qry);
            self::closeConnection($MSSQL_CONN);
            return $result;
        } catch (\Exception $e) {
            $strErr = strval($e);
            $currentDateTime = $this->getDateTimeNow();
            // if ($_SERVER['REMOTE_ADDR'] === '::1') file_put_contents(__DIR__.'/../sql/tmp/error.sql', "-- Executed on $currentDateTime \n$query \n-- $currentDateTime  $strErr");
            throw $e;
        }
    }

    final protected function insert(string $query): bool
    {
        try {
            $MSSQL_CONN = self::getConnection();
            $DB = self::MSSQL_DB;
            odbc_autocommit($MSSQL_CONN, FALSE);
            $currentDateTime = $this->getDateTimeNow();
            if ($_SERVER['REMOTE_ADDR'] === '::1') file_put_contents(__DIR__ . '/../sql/tmp/insert.sql', "-- Executed on $currentDateTime \n$query");
            $qry = odbc_exec($MSSQL_CONN, "USE [$DB]; $query;");
            $result = false;
            if (!odbc_error()) {
                odbc_commit($MSSQL_CONN);
                $result = true;
            } else {
                odbc_rollback($MSSQL_CONN);
                $result = false;
            }
            odbc_free_result($qry);
            self::closeConnection($MSSQL_CONN);
            return $result;
        } catch (\Exception $e) {
            throw $e;
        }
    }

    final protected function validateStringArg(string $arg): string
    {
        try {
            $validatedArg = '';
            $validatedArg = str_replace("'", "''", $arg);
            return $validatedArg;
        } catch (\Exception $e) {
            throw $e;
        }
    }
}