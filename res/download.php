<?php

require_once __DIR__.'/inc/restriction.php';

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

require_once __DIR__.'/inc/globals.php';
require_once __DIR__.'/inc/autoload.php';

session_write_close();
$model = PctpWindowFactory::getObject('PctpWindowController', $_SESSION)->model;

$code = $_GET['code'];
$file = $_GET['file'];
$tabName = preg_replace('/[\d|A-Z]+/', '', $code);
$realAttachmentPath = array_values(array_filter($model->{$tabName.'Tab'}->realAttachment, fn($z) => $z->Code == $code))[0]->realAttachmentPath.$file;
switch ($_GET['option']) {
    case 'download':
        header('Content-Description: File Transfer');
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename='.basename($realAttachmentPath));
        header('Content-Transfer-Encoding: binary');
        header('Expires: 0');
        header('Cache-Control: must-revalidate, post-check=0, pre-check=0');
        header('Pragma: public');
        header('Content-Length: ' . filesize($realAttachmentPath));
        ob_clean();
        flush();
        readfile($realAttachmentPath);
        break;
    case 'view':
        if (!str_contains($realAttachmentPath, '.pdf')) break;
        header('Content-type: application/pdf');
        header('Content-Disposition: inline; filename="'.basename($realAttachmentPath).'"');
        header('Content-Transfer-Encoding: binary');
        header('Accept-Ranges: bytes');
        readfile($realAttachmentPath);
        break;
    default:
        # code...
        break;
}
exit;