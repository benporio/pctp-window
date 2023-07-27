<?php

require_once __DIR__.'/../inc/restriction.php';

class PctpWindowHeader extends ASerializableClass
{
    public string $findText = '';
    public string $bookingDateFrom;
    public string $bookingDateTo;
    public string $deliveryDateFrom = '';
    public string $deliveryDateTo = '';
    public string $clientTag = '';
    public string $truckerTag = '';
    public string $deliveryStatusOptions = '';
    public string $podStatusOptions = '';
    public string $billingStatusOptions = '';
    public string $ptfNo = '';
    public bool $includePtfNo = false;
    public bool $includeBlankBillingStatusOnly = false;
    public string $siRef = '';
    public string $soDocNum = '';
    public string $arDocNum = '';
    public string $apDocNum = '';
    public bool $includeBlankSIRefOnly = false;
    public bool $includeBlankSODocNumOnly = false;
    public bool $includeBlankARDocNumOnly = false;
    public bool $includeBlankAPDocNumOnly = false;

    public function __construct(PctpWindowSettings $settings)
    {
        $this->bookingDateFrom = $settings->initialBookingDateFrom;
        $this->bookingDateTo = $settings->initialBookingDateTo;
    }

    public static function parseHeader(object $dataHeader, PctpWindowSettings $settings): PctpWindowHeader {
        $header = new PctpWindowHeader($settings);
        foreach ((array)$dataHeader as $key => $value) {
            $header->{$key} = gettype($header->{$key}) === 'boolean' ? ($value === 'true' ? true : false) : $value;
        }
        return $header;
    }
}