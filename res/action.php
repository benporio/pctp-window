<?php

require_once __DIR__.'/inc/restriction.php';

try {
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    require_once __DIR__.'/inc/globals.php';
    require_once __DIR__.'/inc/autoload.php';
    $action = isset($_GET['action']) ? $_GET['action'] : (isset($_POST['action']) ? $_POST['action'] : null);
    $data = isset($_POST['data']) ? json_decode(json_encode($_POST['data'])) : null;
    if ($action === null) {
        $fetchData = json_decode(file_get_contents("php://input"));
        $action = $fetchData->action;
        $data = $fetchData->data;
    }
    session_write_close();
    $pctpWindowController = PctpWindowFactory::getObject('PctpWindowController', $_SESSION);
    if ($pctpWindowController === null) {
        $pctpWindowController = new PctpWindowController();
    }

    $actionResult = $pctpWindowController->{$action}($data);
    PctpWindowFactory::storeObject($pctpWindowController, false);
    session_write_close();
    echo $actionResult->echo();

    // if ($action === 'initialize' && $pctpWindowController->model->isInitialized) {
    //     echo json_encode($pctpWindowController->model->hybridHeader);
    // } else {
    //     $actionResult = $pctpWindowController->{$action}($data);
    //     PctpWindowFactory::storeObject($pctpWindowController, false);
    //     echo $actionResult->echo();
    // }


    // $fiber = new Fiber(function (string $action, ?string $data): string {
    //     $pctpWindowController = PctpWindowFactory::getObject('PctpWindowController');
    //     if ($pctpWindowController === null) {
    //         $pctpWindowController = new PctpWindowController();
    //     }

    //     $actionResult = $pctpWindowController->{$action}($data);
    //     PctpWindowFactory::storeObject($pctpWindowController, false);

    //     return $actionResult->echo();
    // });

    // $fiber->start($action, $data);
    // echo $fiber->getReturn();

} catch (\Exception $e) {
    echo json_encode([
        'type' => 'error',
        'message' => strval($e),
    ]);
}
