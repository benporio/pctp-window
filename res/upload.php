<?php

require_once __DIR__.'/inc/restriction.php';

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
require_once __DIR__.'/inc/globals.php';
require_once __DIR__.'/inc/autoload.php';

if ( 0 < $_FILES['file']['error'] ) {
    echo json_encode([
        'result' => 'failed',
        'message' => $_FILES['file']['error']
    ]);
} else {
    try {
        session_write_close();
        $model = PctpWindowFactory::getObject('PctpWindowController', $_SESSION)->model;

        $fileName = $_FILES['file']['name'];
        $code = $_POST['code'];
        $uploadedPathDir = $model->initializeUploadDir($code);
        $fileUploadedPath = $uploadedPathDir.$fileName;
        if ((isset($model->getSettings()->config['ignore_file_attachment_upload_existence']) && $model->getSettings()->config['ignore_file_attachment_upload_existence']) 
            || !file_exists($fileUploadedPath)) {
            if (!file_exists($uploadedPathDir)) {
                mkdir($uploadedPathDir, 0777, true);
            }
            if (move_uploaded_file($_FILES['file']['tmp_name'], $fileUploadedPath)) {
                echo json_encode([
                    'result' => 'success',
                    'message' => $fileName.' file uploaded successfully'
                ]);
            } else {
                if (!file_exists($fileUploadedPath)) {
                    echo json_encode([
                        'result' => 'failed',
                        'message' => $fileName.' file upload failed'
                    ]);
                } else {
                    echo json_encode([
                        'result' => 'success',
                        'message' => $fileName.' file uploaded successfully'
                    ]);
                }
            }
        } else {
            echo json_encode([
                'result' => 'failed',
                'message' => $fileName.' file already exists'
            ]);
        }
    } catch (\Exception $e) {
        echo json_encode([
            'result' => 'failed',
            'message' => $e
        ]);
    }
}

