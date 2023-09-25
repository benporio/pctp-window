<?php
require_once __DIR__ . '/../../res/inc/autoload.php';
$model = PctpWindowFactory::getObject('PctpWindowController')->model;
$header = $model->header;
?>

<div class="row d-flex pr-0 pb-2" width="100%">
    <div class="col-6">
        <?php $labelColumnSize = 2 ?>
        <?php $fieldColumnSize = 10 ?>
        <div class="row d-flex">
            <div class="col-<?= $labelColumnSize ?>">
                <label for="txtfind" class="col-form-label" style="color: black;">FIND</label>
            </div>
            <div class="col-<?= $fieldColumnSize ?> align-self-start">
                <input type="search" id="txtfind" style="width: 100%;" data-pctp-header="findText" placeholder="Search here..." title="This will search all the alphanumeric fields of the current tab.">
            </div>
        </div>
        <div class="row d-flex">
            <div class="col-<?= $labelColumnSize ?>">
                <!-- <label for="txtfind" class="col-form-label" style="color: black;">FIND</label> -->
            </div>
            <div class="col-<?= $fieldColumnSize ?> align-self-start">
                <div class="row d-flex">
                    <div class="col">
                        <div class="row d-flex">
                            <div class="col-auto">
                                <label for="txtsiref" class="col-form-label" style="color: black;">SI #</label>
                            </div>
                            <div class="col ml-0 pl-0">
                                <input id="txtsiref" style="width: 100%;" data-pctp-header="siRef" placeholder="Type SI #...">
                            </div>
                            <div class="col-auto ml-0 pl-0" style="vertical-align: middle;">
                                <input class="exclude-check" id="chksiref" type="checkbox" data-pctp-header="includeBlankSIRefOnly" title="Marking this will include only blank SI Reference">
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="row d-flex">
                            <div class="col-auto">
                                <label for="txtsodocnum" class="col-form-label" style="color: black;">SO #</label>
                            </div>
                            <div class="col ml-0 pl-0">
                                <input id="txtsodocnum" style="width: 100%;" data-pctp-header="soDocNum" placeholder="Type SO #...">
                            </div>
                            <div class="col-auto ml-0 pl-0" style="vertical-align: middle;">
                                <input class="exclude-check" id="chksodocnum" type="checkbox" data-pctp-header="includeBlankSODocNumOnly" title="Marking this will include only blank SO #">
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="row d-flex">
                            <div class="col-auto">
                                <label for="txtardocnum" class="col-form-label" style="color: black;">AR #</label>
                            </div>
                            <div class="col ml-0 pl-0">
                                <input id="txtardocnum" style="width: 100%;" data-pctp-header="arDocNum" placeholder="Type AR #...">
                            </div>
                            <div class="col-auto ml-0 pl-0" style="vertical-align: middle;">
                                <input class="exclude-check" id="chkardocnum" type="checkbox" data-pctp-header="includeBlankARDocNumOnly" title="Marking this will include only blank AR #">
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="row d-flex">
                            <div class="col-auto">
                                <label for="txtapdocnum" class="col-form-label" style="color: black;">AP #</label>
                            </div>
                            <div class="col ml-0 pl-0">
                                <input id="txtapdocnum" style="width: 100%;" data-pctp-header="apDocNum" placeholder="Type AP #...">
                            </div>
                            <div class="col-auto ml-0 pl-0" style="vertical-align: middle;">
                                <input class="exclude-check" id="chkapdocnum" type="checkbox" data-pctp-header="includeBlankAPDocNumOnly" title="Marking this will include only blank AP #">
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="row d-flex">
            <div class="col-<?= $labelColumnSize ?>">
                <label class="col-form-label" style="color: black;">BOOKING DATE</label>
            </div>
            <div class="col-<?= $fieldColumnSize ?>">
                <div class="row d-flex">
                    <div class="col">
                        <div class="row justify-content-center">
                            <div class="col-auto text-right">
                                <label for="txtfrombookingdate" class="col-form-label" style="color: black;">FROM</label>
                            </div>
                            <div class="col-6">
                                <div class="row">
                                    <input value="<?= !(bool)$header->bookingDateFrom ? '' : PctpWindowTabHelper::getInstance($model->settings)->SAPDateFormatter($header->bookingDateFrom) ?>" type="text" class="col dateInputFace header" style="width: 100%; text-align: center; box-sizing: border-box;" placeholder="Enter date...">
                                    <input class="dateInputVal" data-pctp-header="bookingDateFrom" id="txtfrombookingdate" style="width: 30px; box-sizing: border-box;" type="date">
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="row justify-content-center">
                            <div class="col-auto text-right">
                                <label for="txttobookingdate" class="col-form-label" style="color: black;">TO</label>
                            </div>
                            <div class="col-6">
                                <div class="row">
                                    <input value="<?= !(bool)$header->bookingDateTo ? '' : PctpWindowTabHelper::getInstance($model->settings)->SAPDateFormatter($header->bookingDateTo) ?>" type="text" class="col dateInputFace header" style="width: 100%; text-align: center; box-sizing: border-box;" placeholder="Enter date...">
                                    <input class="dateInputVal" data-pctp-header="bookingDateTo" id="txttobookingdate" style="width: 30px; box-sizing: border-box;" type="date">
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="row d-flex">
            <div class="col-<?= $labelColumnSize ?>">
                <label class="col-form-label" style="color: black;">DELIVERY DATE</label>
            </div>
            <div class="col-<?= $fieldColumnSize ?>">
                <div class="row d-flex">
                    <div class="col">
                        <div class="row justify-content-center">
                            <div class="col-auto text-right">
                                <label for="txtfromdeliverydate" class="col-form-label" style="color: black;">FROM</label>
                            </div>
                            <div class="col-6">
                                <div class="row">
                                    <input value="<?= !(bool)$header->deliveryDateFrom ? '' : PctpWindowTabHelper::getInstance($model->settings)->SAPDateFormatter($header->deliveryDateFrom) ?>" type="text" class="col dateInputFace header" style="width: 100%; text-align: center; box-sizing: border-box;" placeholder="Enter date...">
                                    <input class="dateInputVal" data-pctp-header="deliveryDateFrom" id="txtfromdeliverydate" style="width: 30px; box-sizing: border-box;" type="date">
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="row justify-content-center">
                            <div class="col-auto text-right">
                                <label for="txttodeliverydate" class="col-form-label" style="color: black;">TO</label>
                            </div>
                            <div class="col-6">
                                <div class="row">
                                    <input value="<?= !(bool)$header->deliveryDateTo ? '' : PctpWindowTabHelper::getInstance($model->settings)->SAPDateFormatter($header->deliveryDateTo) ?>" type="text" class="col dateInputFace header" style="width: 100%; text-align: center; box-sizing: border-box;" placeholder="Enter date...">
                                    <input class="dateInputVal" data-pctp-header="deliveryDateTo" id="txttodeliverydate" style="width: 30px; box-sizing: border-box;" type="date">
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <!-- <div class="row d-flex">
            <div class="col-<?= $labelColumnSize ?>">
                <label class="col-form-label" style="color: black;">BOOKING DATE</label>
            </div>
            <div class="col-<?= $fieldColumnSize ?>">
                <div class="row d-flex">
                    <div class="col">
                        <div class="row justify-content-center">
                            <div class="col-auto text-right">
                                <label for="txtfrombookingdate" class="col-form-label" style="color: black;">FROM</label>
                            </div>
                            <div class="col-6">
                                <input type="date" id="txtfrombookingdate" style="width: 100%;" data-pctp-header="bookingDateFrom">
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="row justify-content-center">
                            <div class="col-auto text-right">
                                <label for="txttobookingdate" class="col-form-label" style="color: black;">TO</label>
                            </div>
                            <div class="col-6">
                                <input type="date" id="txttobookingdate" style="width: 100%;" data-pctp-header="bookingDateTo">
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="row d-flex">
            <div class="col-<?= $labelColumnSize ?>">
                <label class="col-form-label" style="color: black;">DELIVERY DATE</label>
            </div>
            <div class="col-<?= $fieldColumnSize ?>">
                <div class="row d-flex">
                    <div class="col">
                        <div class="row justify-content-center">
                            <div class="col-auto text-right">
                                <label for="txtfromdeliverydate" class="col-form-label" style="color: black;">FROM</label>
                            </div>
                            <div class="col-6">
                                <input type="date" id="txtfromdeliverydate" style="width: 100%;" data-pctp-header="deliveryDateFrom">
                            </div>
                        </div>
                    </div>
                    <div class="col">
                        <div class="row justify-content-center">
                            <div class="col-auto text-right">
                                <label for="txttodeliverydate" class="col-form-label" style="color: black;">TO</label>
                            </div>
                            <div class="col-6">
                                <input type="date" id="txttodeliverydate" style="width: 100%;" data-pctp-header="deliveryDateTo">
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div> -->
        <div class="row d-flex">
            <div class="col-<?= $labelColumnSize ?>">
                <label for="txtclienttag" class="col-form-label" style="color: black;">CLIENT TAG</label>
            </div>
            <div class="col-<?= $fieldColumnSize ?> align-self-start">
                <input type="search" id="txtclienttag" style="width: 100%;" data-pctp-header="clientTag" placeholder="Type client tag...">
            </div>
        </div>
        <div class="row d-flex">
            <div class="col-<?= $labelColumnSize ?>">
                <label for="txttruckertag" class="col-form-label" style="color: black;">TRUCKER TAG</label>
            </div>
            <div class="col-<?= $fieldColumnSize ?> align-self-start">
                <input type="search" id="txttruckertag" style="width: 100%;" data-pctp-header="truckerTag" placeholder="Type trucker tag...">
            </div>
        </div>
        <div class="row d-flex">
            <div class="col-<?= $labelColumnSize ?>">
                <label for="seldeliverystatus" class="col-form-label" style="color: black;">DELIVERY STATUS</label>
            </div>
            <div class="col-<?= $fieldColumnSize ?> align-self-start">
                <select id="seldeliverystatus" style="width: 100%;" data-pctp-header="deliveryStatusOptions" data-pctp-options="deliveryStatusOptions">
                    <option value="" style="display: none;" disabled selected>Select...</option>
                    <option value="">Any</option>
                </select>
            </div>
        </div>
        <div class="row d-flex">
            <div class="col-<?= $labelColumnSize ?>">
                <label for="selpodstatus" class="col-form-label" style="color: black;">POD Status</label>
            </div>
            <div class="col-<?= $fieldColumnSize ?> align-self-start">
                <select id="selpodstatus" style="width: 100%;" data-pctp-header="podStatusOptions" data-pctp-options="podStatusOptions">
                    <option value="" style="display: none;" disabled selected>Select...</option>
                    <option value="">Any</option>
                </select>
            </div>
        </div>
        <div class="row d-flex">
            <div class="col-<?= $labelColumnSize ?>">
                <label for="selbillingstatus" class="col-form-label" style="color: black;">Billing Status</label>
            </div>
            <div class="col-<?= $fieldColumnSize ?> align-self-start">
                <select id="selbillingstatus" style="width: 100%;" data-pctp-header="billingStatusOptions" data-pctp-options="billingStatusOptions">
                    <option value="" style="display: none;" disabled selected>Select...</option>
                    <option value="">Any</option>
                </select>
            </div>
        </div>
        <div class="row d-flex">
            <div class="col-<?= $labelColumnSize ?>">
                <label for="txtptfno" class="col-form-label" style="color: black;">PTF No.</label>
            </div>
            <div class="col-<?= $fieldColumnSize ?> align-self-start">
                <input onkeyup="if($(this).val()!==''){$('#chkptfno').prop('checked',false);$('#chkptfno').attr('disabled',true);}else{$('#chkptfno').attr('disabled',false)}" class="clstxtptfno" type="search" id="txtptfno" style="width: 100%;" data-pctp-header="ptfNo" placeholder="Type PTF No...">
            </div>
        </div>
    </div>
    <div class="col-2">
        <div class="row d-flex">
            <div class="col-4">
                <button type="button" data-pctp-action="find" id="btnfind" class="btn btn-warning btn-rounded" style="color: black; font-weight: bold; width:100%; height:30px; background: linear-gradient(to bottom, #FCF6BA, #BF953F);">FIND</button>
            </div>
            <div class="col-auto">
                <span class="findTimeElapsed"></span>
            </div>
        </div>
        <div class="row d-flex align-items-start clschkpodstatusdiv" style="margin-top: 235px; vertical-align: middle;">
            <div class="col-12" style="vertical-align: middle;">
                <div class="row d-flex">
                    <div class="col-auto mr-0 pr-0" style="vertical-align: middle;">
                        <input type="checkbox" id="chkpodstatus" data-pctp-header="includeBlankPodStatusOnly" style="width: 25px; height: 25px; margin-right: 10px;">
                    </div>
                    <div class="col m-0 p-0" style="display: inline; vertical-align: middle; margin-bottom: 50px;">
                        <span>Inlude Blank POD Status only</span>
                    </div>
                </div>
            </div>
        </div>
        <div class="row d-flex align-items-start clschkbillingstatusdiv" style="margin-top: 6px; vertical-align: middle;">
            <div class="col-12" style="vertical-align: middle;">
                <div class="row d-flex">
                    <div class="col-auto mr-0 pr-0" style="vertical-align: middle;">
                        <input type="checkbox" id="chkbillingstatus" data-pctp-header="includeBlankBillingStatusOnly" style="width: 25px; height: 25px; margin-right: 10px;">
                    </div>
                    <div class="col m-0 p-0" style="display: inline; vertical-align: middle; margin-bottom: 50px;">
                        <span>Inlude Blank Billing Status only</span>
                    </div>
                </div>
            </div>
        </div>
        <div class="row d-flex align-items-start clschkptfnodiv" style="margin-top: 7px; vertical-align: middle;">
            <div class="col-12" style="vertical-align: middle;">
                <div class="row d-flex">
                    <div class="col-auto mr-0 pr-0" style="vertical-align: middle;">
                        <input type="checkbox" id="chkptfno" data-pctp-header="includePtfNo" style="width: 25px; height: 25px; margin-right: 10px;">
                    </div>
                    <div class="col m-0 p-0" style="display: inline; vertical-align: middle; margin-bottom: 50px;">
                        <span>Inlude empty PTF No only</span>
                    </div>
                </div>
            </div>
        </div>
    </div>
    <div class="col-4">
        <div class="row d-flex justify-content-end" style="vertical-align: middle;">
            <div class="node-notify-info col-auto align-self-end ml-auto mb-3" style="vertical-align: middle; text-align: right;">No background activity</div>
            <div class="led-box col-1 align-self-end" style="vertical-align: middle;">
                <div id="nodenotify" class="led" title="No background activity"></div>
            </div>
        </div>
    </div>
</div>