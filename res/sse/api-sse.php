<?php

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
require_once __DIR__ . '/../inc/globals.php';
require_once __DIR__ . '/../inc/autoload.php';

header('Content-Type: text/event-stream');
header('Cache-Control: no-cache');

$messageCounter = 1;
$sessionKey = basename(__FILE__);

if (isset($_SESSION[$sessionKey]) && $_SESSION[$sessionKey] === 'enabled') {
    set_time_limit(1200);
    $_SESSION[$sessionKey] = 'disabled';
    $actionName = $_SESSION['action'];
    $appendedData = (array)json_decode($_SESSION['appendedData']);
    unset($_SESSION['appendedData']);
    unset($_SESSION['action']);
    session_write_close();
    $pctpWindowController = PctpWindowFactory::getObject('PctpWindowController', $_SESSION);
    if ($pctpWindowController === null) {
        $pctpWindowController = new PctpWindowController();
    }
    $totalCount = floatval($pctpWindowController->model->{$appendedData['tab'].'Tab'}->fetchTableRowsCount);
    $start = 0;
    $length = $pctpWindowController->model->getSettings()->config['excel_download_rows_interval'];
    $i = 0;
    while (true) {
        $start = $i * $length;
        $dataTableSetting = [];
        $dataTableSetting['start'] = $start;
        $dataTableSetting['length'] = $length;
        $appendedData['dataTableSetting'] = (object)$dataTableSetting;
        $action = PctpAPI::getInstance($pctpWindowController->model->settings)->{$actionName}($pctpWindowController->model, (object)$appendedData);
        $result = json_decode($action->echo());
        if ($i > 0) {
            unset($result->data[0]);
            $result->data = array_values($result->data);
        }
        $totalCount -= $length;
        $i++;
        echo "id: " . date("h:i:s", time()) . PHP_EOL;
        echo 'data: ' . json_encode(['status' => $totalCount < 0 ? 'complete' : 'ongoing', 'data' => $result]) . PHP_EOL;
        echo PHP_EOL;
        ob_flush();
        flush();
        if ($totalCount < 0) break;
    }
    set_time_limit(300);
}

