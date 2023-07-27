<?php

require_once __DIR__.'/../inc/restriction.php';

enum SAPDocumentStructureType: int {
    case SALES_ORDER = 17;
    case AR_INVOICE = 13;
    case AP_INVOICE = 18;

    public function name(): string
    {
        return match($this) 
        {
            SAPDocumentStructureType::SALES_ORDER => 'SALES_ORDER',
            SAPDocumentStructureType::AR_INVOICE => 'AR_INVOICE',
            SAPDocumentStructureType::AP_INVOICE => 'AP_INVOICE',
        };
    }
}