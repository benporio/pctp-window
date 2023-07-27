<?php

require_once __DIR__.'/../inc/restriction.php';

enum PctpErrorType {
    case FILE_NOT_UPLOADED;
    case FILE_NOT_DELETED;
    case SAP_ERROR;

    public function message(): string
    {
        return match($this) 
        {
            PctpErrorType::FILE_NOT_UPLOADED => 'File attachment upload failed',   
            PctpErrorType::FILE_NOT_DELETED => 'File attachment removal failed',   
            PctpErrorType::SAP_ERROR => 'SAP Error Message',   
        };
    }

    public function code(): int
    {
        return match($this) 
        {
            PctpErrorType::FILE_NOT_UPLOADED => 1601,   
            PctpErrorType::FILE_NOT_DELETED => 1602, 
            PctpErrorType::SAP_ERROR => 1603, 
        };
    }
}