<?php

require_once __DIR__.'/../inc/restriction.php';

class PctpError extends Exception
{
    public function __construct(PctpErrorType $pctpErrorType)
    {
        parent::__construct($pctpErrorType->message(), $pctpErrorType->code());
    }

    public function __toString() 
    {
        return __CLASS__.": [{$this->code}]: {$this->message}";
    }
}