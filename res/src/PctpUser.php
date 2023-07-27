<?php

require_once __DIR__.'/../inc/restriction.php';

class PctpUser extends ASerializableClass
{
    public ?TabAccessType $summaryAccess;
    public ?TabAccessType $podAccess;
    public ?TabAccessType $billingAccess;
    public ?TabAccessType $tpAccess;
    public ?TabAccessType $pricingAccess;
    public ?TabAccessType $treasuryAccess;
    public function __construct()
    {
        $loggedInUserCode = $_SESSION['SESS_USERCODE'];
        $result = SAPAccessManager::getInstance()->getRows(
        "   SELECT
                POD,
                BILLING,
                TP,
                PRICING
            FROM [USER-COMMON].[dbo].[@OUSR]
            WHERE UserCode = '$loggedInUserCode'
        ");
        if (!(bool)$result) {
            $this->summaryAccess = TabAccessType::NONE;
            $this->podAccess = TabAccessType::NONE;
            $this->billingAccess = TabAccessType::NONE;
            $this->tpAccess = TabAccessType::NONE;
            $this->pricingAccess = TabAccessType::NONE;
            $this->treasuryAccess = TabAccessType::NONE;
        } else {
            $this->summaryAccess = TabAccessType::FULL;
            $this->podAccess = TabAccessType::tryFrom(strtoupper($result[0]->POD));
            $this->billingAccess = TabAccessType::tryFrom(strtoupper($result[0]->BILLING));
            $this->tpAccess = TabAccessType::tryFrom(strtoupper($result[0]->TP));
            $this->pricingAccess = TabAccessType::tryFrom(strtoupper($result[0]->PRICING));
            $this->treasuryAccess = TabAccessType::FULL;
        }
    }
}