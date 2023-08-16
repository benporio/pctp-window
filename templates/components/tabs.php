<?php
require_once __DIR__ . '/../../res/inc/autoload.php';
$user = PctpWindowFactory::getObject('PctpWindowController')->model->user;
$hasActiveTab = false;
$setActiveTab = '';
?>

<div class="row d-flex align-items-center mt-5">
    <div class="col-12">
        <ul class="nav nav-tabs pt-2" id="pctpwindowtabs" role="tablist">
            <?php if ($user->summaryAccess === TabAccessType::FULL || $user->summaryAccess === TabAccessType::VIEW) : ?>
                <li class="nav-item">
                    <a class="nav-link <?= !$hasActiveTab ? 'active' : '' ?>" id="summarytab" data-toggle="tab" href="#summarytabpane" role="tab" aria-controls="summarytabpane" aria-selected="true" style="color: black; font-weight:bold">
                        <div class="row">
                            <div class="col-auto">SUMMARY</div>
                            <div id="summaryloading" class="col-auto text-right loading ml-auto">
                                <span><i class="fas fa-spinner fa-pulse fa-lg" style="color: blue;"></i></span>
                            </div>
                            <div id="summaryexcel" class="col-auto text-right loading ml-auto exceldownload d-none">
                                <span><i id="summaryexcelicon" class="fas fa-file-excel" style="color: green; animation: 'none';" title="Click to download summary-tab-excel.xlsx"></i></span>
                            </div>
                        </div>
                    </a>
                </li>
                <?php 
                    if (!$hasActiveTab) {
                        $setActiveTab = 'SUMMARY';
                        $hasActiveTab = true; 
                    }
                ?>
            <?php endif ?>
            <?php if ($user->podAccess === TabAccessType::FULL || $user->podAccess === TabAccessType::VIEW) : ?>
                <li class="nav-item">
                    <a class="nav-link <?= !$hasActiveTab ? 'active' : '' ?>" id="podtab" data-toggle="tab" href="#podtabpane" role="tab" aria-controls="podtabpane" aria-selected="false" style="color: black; font-weight:bold">
                        <div class="row">
                            <div class="col-auto">POD</div>
                            <div id="podloading" class="col-auto text-right loading ml-auto">
                                <span><i class="fas fa-spinner fa-pulse fa-lg" style="color: blue;"></i></span>
                            </div>
                            <div id="podexcel" class="col-auto text-right loading ml-auto exceldownload d-none">
                                <span><i id="podexcelicon" class="fas fa-file-excel" style="color: green; animation: 'none';" title="Click to download pod-tab-excel.xlsx"></i></span>
                            </div>
                        </div>
                    </a>
                </li>
                <?php 
                    if (!$hasActiveTab) {
                        $setActiveTab = 'POD';
                        $hasActiveTab = true; 
                    }
                ?>
            <?php endif ?>
            <?php if ($user->billingAccess === TabAccessType::FULL || $user->billingAccess === TabAccessType::VIEW) : ?>
                <li class="nav-item">
                    <a class="nav-link <?= !$hasActiveTab ? 'active' : '' ?>" id="billingtab" data-toggle="tab" href="#billingtabpane" role="tab" aria-controls="billingtabpane" aria-selected="false" style="color: black; font-weight:bold">
                        <div class="row">
                            <div class="col-auto">BILLING</div>
                            <div id="billingloading" class="col-auto text-right loading ml-auto">
                                <span><i class="fas fa-spinner fa-pulse fa-lg" style="color: blue;"></i></span>
                            </div>
                            <div id="billingexcel" class="col-auto text-right loading ml-auto exceldownload d-none">
                                <span><i id="billingexcelicon" class="fas fa-file-excel" style="color: green; animation: 'none';" title="Click to download billing-tab-excel.xlsx"></i></span>
                            </div>
                        </div>
                    </a>
                </li>
                <?php 
                    if (!$hasActiveTab) {
                        $setActiveTab = 'BILLING';
                        $hasActiveTab = true; 
                    }
                ?>
            <?php endif ?>
            <?php if ($user->tpAccess === TabAccessType::FULL || $user->tpAccess === TabAccessType::VIEW) : ?>
                <li class="nav-item">
                    <a class="nav-link <?= !$hasActiveTab ? 'active' : '' ?>" id="tptab" data-toggle="tab" href="#tptabpane" role="tab" aria-controls="tptabpane" aria-selected="false" style="color: black; font-weight:bold">
                        <div class="row">
                            <div class="col-auto">TP</div>
                            <div id="tploading" class="col-auto text-right loading ml-auto">
                                <span><i class="fas fa-spinner fa-pulse fa-lg" style="color: blue;"></i></span>
                            </div>
                            <div id="tpexcel" class="col-auto text-right loading ml-auto exceldownload d-none">
                                <span><i id="tpexcelicon" class="fas fa-file-excel" style="color: green; animation: 'none';" title="Click to download tp-tab-excel.xlsx"></i></span>
                            </div>
                        </div>
                    </a>
                </li>
                <?php 
                    if (!$hasActiveTab) {
                        $setActiveTab = 'TP';
                        $hasActiveTab = true; 
                    }
                ?>
            <?php endif ?>
            <?php if ($user->pricingAccess === TabAccessType::FULL || $user->pricingAccess === TabAccessType::VIEW) : ?>
                <li class="nav-item">
                    <a class="nav-link <?= !$hasActiveTab ? 'active' : '' ?>" id="pricingtab" data-toggle="tab" href="#pricingtabpane" role="tab" aria-controls="pricingtabpane" aria-selected="false" style="color: black; font-weight:bold">
                        <div class="row">
                            <div class="col-auto">PRICING</div>
                            <div id="pricingloading" class="col-auto text-right loading ml-auto">
                                <span><i class="fas fa-spinner fa-pulse fa-lg" style="color: blue;"></i></span>
                            </div>
                            <div id="pricingexcel" class="col-auto text-right loading ml-auto exceldownload d-none">
                                <span><i id="pricingexcelicon" class="fas fa-file-excel" style="color: green; animation: 'none';" title="Click to download pricing-tab-excel.xlsx"></i></span>
                            </div>
                        </div>
                    </a>
                </li>
                <?php 
                    if (!$hasActiveTab) {
                        $setActiveTab = 'PRICING';
                        $hasActiveTab = true; 
                    }
                ?>
            <?php endif ?>
            <?php if ($user->treasuryAccess === TabAccessType::FULL || $user->treasuryAccess === TabAccessType::VIEW) : ?>
                <li class="nav-item">
                    <a class="nav-link <?= !$hasActiveTab ? 'active' : '' ?>" id="treasurytab" data-toggle="tab" href="#treasurytabpane" role="tab" aria-controls="treasurytabpane" aria-selected="false" style="color: black; font-weight:bold">
                        <div class="row">
                            <div class="col-auto">TREASURY</div>
                            <div id="treasuryloading" class="col-auto text-right loading ml-auto">
                                <span><i class="fas fa-spinner fa-pulse fa-lg" style="color: blue;"></i></span>
                            </div>
                            <div id="treasuryexcel" class="col-auto text-right loading ml-auto exceldownload d-none">
                                <span><i id="treasuryexcelicon" class="fas fa-file-excel" style="color: green; animation: 'none';" title="Click to download treasury-tab-excel.xlsx"></i></span>
                            </div>
                        </div>
                    </a>
                </li>
                <?php 
                    if (!$hasActiveTab) {
                        $setActiveTab = 'TREASURY';
                        $hasActiveTab = true; 
                    }
                ?>
            <?php endif ?>
        </ul>
    </div>
</div>
<div id="resultDiv" class="tab-content col-12 p-0 m-0">
    <?php if ($user->summaryAccess === TabAccessType::FULL || $user->summaryAccess === TabAccessType::VIEW) : ?>
        <div class="tab-pane fade <?= $setActiveTab === 'SUMMARY' ? 'show active' : '' ?> scrollableDiv" data-pctp-model="summary" id="summarytabpane" role="tabpanel" aria-labelledby="summarytabpane" style="min-height: 0px; max-height: 750px; overflow: auto;">
            <div id="summarytabpaneloading" style="padding-top: 10px;" class="text-center">
                <h4>LOADING ROWS PLEASE WAIT...</h4>
            </div>
            <div id="summarytabpanecontent" style="white-space: nowrap;" class="text-center d-none">
            </div>
        </div>
    <?php endif ?>
    <?php if ($user->podAccess === TabAccessType::FULL || $user->podAccess === TabAccessType::VIEW) : ?>
        <div class="tab-pane fade <?= $setActiveTab === 'POD' ? 'show active' : '' ?> scrollableDiv" data-pctp-model="pod" id="podtabpane" role="tabpanel" aria-labelledby="podtabpane" style="min-height: 0px; max-height: 750px; overflow: auto;">
            <div id="podtabpaneloading" style="padding-top: 10px;" class="text-center">
                <h4>LOADING ROWS PLEASE WAIT...</h4>
            </div>
            <div id="podtabpanecontent" style="white-space: nowrap;" class="text-center d-none">
            </div>
        </div>
    <?php endif ?>
    <?php if ($user->billingAccess === TabAccessType::FULL || $user->billingAccess === TabAccessType::VIEW) : ?>
        <div class="tab-pane fade <?= $setActiveTab === 'BILLING' ? 'show active' : '' ?> scrollableDiv" data-pctp-model="billing" id="billingtabpane" role="tabpanel" aria-labelledby="billingtabpane" style="min-height: 0px; max-height: 750px; overflow: auto;">
            <div id="billingtabpaneloading" style="padding-top: 10px;" class="text-center">
                <h4>LOADING ROWS PLEASE WAIT...</h4>
            </div>
            <div id="billingtabpanecontent" style="white-space: nowrap;" class="text-center d-none">
            </div>
        </div>
    <?php endif ?>
    <?php if ($user->tpAccess === TabAccessType::FULL || $user->tpAccess === TabAccessType::VIEW) : ?>
        <div class="tab-pane fade <?= $setActiveTab === 'TP' ? 'show active' : '' ?> scrollableDiv" data-pctp-model="tp" id="tptabpane" role="tabpanel" aria-labelledby="tptabpane" style="min-height: 0px; max-height: 750px; overflow: auto;">
            <div id="tptabpaneloading" style="padding-top: 10px;" class="text-center">
                <h4>LOADING ROWS PLEASE WAIT...</h4>
            </div>
            <div id="tptabpanecontent" style="white-space: nowrap;" class="text-center d-none">
            </div>
        </div>
    <?php endif ?>
    <?php if ($user->pricingAccess === TabAccessType::FULL || $user->pricingAccess === TabAccessType::VIEW) : ?>
        <div class="tab-pane fade <?= $setActiveTab === 'PRICING' ? 'show active' : '' ?> scrollableDiv" data-pctp-model="pricing" id="pricingtabpane" role="tabpanel" aria-labelledby="pricingtabpane" style="min-height: 0px; max-height: 750px; overflow: auto;">
            <div id="pricingtabpaneloading" style="padding-top: 10px;" class="text-center">
                <h4>LOADING ROWS PLEASE WAIT...</h4>
            </div>
            <div id="pricingtabpanecontent" style="white-space: nowrap;" class="text-center d-none">
            </div>
        </div>
    <?php endif ?>
    <?php if ($user->treasuryAccess === TabAccessType::FULL || $user->treasuryAccess === TabAccessType::VIEW) : ?>
        <div class="tab-pane fade <?= $setActiveTab === 'TREASURY' ? 'show active' : '' ?> scrollableDiv" data-pctp-model="treasury" id="treasurytabpane" role="tabpanel" aria-labelledby="treasurytabpane" style="min-height: 0px; max-height: 750px; overflow: auto;">
            <div id="treasurytabpaneloading" style="padding-top: 10px;" class="text-center">
                <h4>LOADING ROWS PLEASE WAIT...</h4>
            </div>
            <div id="treasurytabpanecontent" style="white-space: nowrap;" class="text-center d-none">
            </div>
        </div>
    <?php endif ?>
</div>