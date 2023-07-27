<?php

require_once __DIR__.'/inc/restriction.php';

try {
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    require_once __DIR__.'/inc/globals.php';
    require_once __DIR__.'/inc/autoload.php';
    $pctpWindowController = PctpWindowFactory::getObject('PctpWindowController', $_SESSION);
    if ($pctpWindowController === null) {$pctpWindowController = new PctpWindowController();}
    $action = isset($_GET['action']) ? $_GET['action'] : $_POST['action'];
    $data = isset($_POST['data']) ? json_decode(json_encode($_POST['data'])) : null;
    $appendedData = (array)$data;
    if ($action === 'getTableRowsDataWithHeaders' && (bool)$pctpWindowController->model->getSettings()->config['enable_excel_background_download']) {
        $_SESSION['api-sse.php'] = 'enabled';
        $_SESSION['action'] = $action;
        $_SESSION['appendedData'] = json_encode($appendedData);
        session_write_close();
        echo json_encode([
            'type' => 'info',
            'message' => 'api-sse.php is enabled'
        ]);
    } else {
        if ($action === 'fetchDataRows') {
            $dataTableSetting = [];
            if (isset($_POST['order'])) {
                $dataTableSetting['order'] = $_POST['order'];
            }
            $dataTableSetting['draw'] = $_POST['draw'];
            $dataTableSetting['start'] = $_POST['start'];
            $dataTableSetting['length'] = $_POST['length'];
            $appendedData['dataTableSetting'] = (object)$dataTableSetting;
        }
        $action = PctpAPI::getInstance($pctpWindowController->model->settings)->{$action}($pctpWindowController->model, (object)$appendedData);
        PctpWindowFactory::storeObject($pctpWindowController, false);
        session_write_close();
        echo $action->echo();
    }
} catch (\Exception $e) {
    echo json_encode([
        'type' => 'error',
        'message' => strval($e),
    ]);
}