<?php

include '../../head.php';

?>

<!-- Page Wrapper -->
<div id="wrapper">
    <?php
    include '../../sidebar.php';


    $UserId = $_SESSION['SESS_USERID'];
    $UserCode = $_SESSION['SESS_USERCODE'];
    $UserName = $_SESSION['SESS_NAME'];
    ?>


    <!-- Content Wrapper -->
    <div id="content-wrapper" class="d-flex flex-column">

        <!-- Main Content -->
        <div id="content" style="background-color: white;">

            <?php
            include '../../topbar.php';
            ?>

            <?php
            if (session_status() === PHP_SESSION_NONE) {
                session_start();
            }
            require_once __DIR__ . '/../res/inc/globals.php';
            require_once __DIR__ . '/../res/inc/autoload.php';

            $pctpWindowController = PctpWindowFactory::getObject('PctpWindowController', $_SESSION);
            if ($pctpWindowController === null || !isset($pctpWindowController->model)) {
                $pctpWindowController = new PctpWindowController();
                PctpWindowFactory::storeObject($pctpWindowController, false);
            }

            // $pctpWindowController = new PctpWindowController(); 
            // PctpWindowFactory::storeObject($pctpWindowController, false);
            ?>

            <!-- Begin Page Content -->
            <div class="container-fluid" style="margin-left: 1px !important; padding-left: 1px !important;">
                <!-- Page Heading -->

                <!-- DataTales Example -->
                <div class="card shadow mb-4" id="windowmain" style="background-color:#E8E8E8 !important; border: none !important">
                    <div class="row pr-0 " width="100%">
                        <div class="col-lg-12" id="containerSystem" style="margin-right: 0px !important; padding-right: 0px !important; ">
                            <div class="card-header py-0" style="background-color: #A8A8A8; border-bottom-width: thick; border-color: #f0ad4e;">
                                <div class="row">
                                    <div class="col-lg-6 col-md-6 col-sm-6">
                                        <h5 class="mt-2 font-weight-bold " style="color: black;">PCTP WINDOW</h5>
                                    </div>

                                </div>
                            </div>
                            <div class="card-body " id="window" style="background-color: #F5F5F5; border-right: 1px solid #A0A0A0">
                                <form class="user responsive " id="form" width="100%">

                                    <!-- Tabs structure -->
                                    <?php include __DIR__ . '/components/header-fields.php' ?>

                                    <!-- Tabs structure -->
                                    <?php include __DIR__ . '/components/tabs.php' ?>

                                    <!-- Tabs structure -->
                                    <?php include __DIR__ . '/components/bottom-buttons.php' ?>

                                </form>
                            </div>
                            <!-- End of Main Content -->
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <!-- End of Content Wrapper -->

    </div>
    <!-- End of Page Wrapper -->

    <!-- Scroll to Top Button-->
    <a class="scroll-to-top rounded" href="#page-top">
        <i class="fas fa-angle-up"></i>
    </a>

    <!-- Loading animation -->
    <?php include __DIR__ . '/components/loading-animation.php' ?>

    <!--Upload Modal-->
    <div class="modal fade " id="uploadmodal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true" data-backdrop="false" style="margin-top: 300px !important;">
        <div class="modal-dialog modal-xl" role="document" style="width:100%">
            <!--Content-->
            <div class="modal-content-full-width modal-content">
                <!--Header-->
                <div class="modal-header" style="background-color: #A8A8A8; border-bottom-width: thick; border-color: #f0ad4e; ">
                    <h4 class="modal-title w-100" id="uploadmodaltitle" style="color:black; font-size:15px !important;">Attachment</h4>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <!--Body-->
                <div class="modal-body"></div>
                <!--Footer-->
                <div class="modal-footer" style="background-color: none !important;">
                    <input onchange="fileUploadRemoveListener(this)" class="d-none" type="file" name="fileupload" id="fileupload">
                    <button onclick="$('#fileupload').trigger('click')" id="uploadmodalbtnupload" type="button" class="btn btn-secondary"></button>
                </div>
            </div>
            <!--Content-->
        </div>
    </div>
    <!--Upload Modal-->

    <!--Reusable Prompt Modal-->
    <div class="modal fade " id="promptModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true" data-backdrop="false" style="margin-top: 300px !important;">
        <div class="modal-dialog modal-xl" role="document" style="width:100%">
            <!--Content-->
            <div class="modal-content-full-width modal-content">
                <!--Header-->
                <div class="modal-header" style="background-color: #A8A8A8; border-bottom-width: thick; border-color: #f0ad4e; ">
                    <h4 class="modal-title w-100" id="promptTitle" style="color:black; font-size:15px !important;"></h4>
                </div>
                <!--Body-->
                <div class="modal-body">
                    <h6 class="modal-title w-100" id="promptMessage" style="color:black"></h6>
                    <br>
                    <br>
                    <h6 class="modal-title w-100" id="promptInfo" style="color:black"></h6>
                </div>
                <!--Footer-->
                <div class="modal-footer" style="background-color: none !important;">
                    <button id="btnPrompt1" type="button" class="btn btn-secondary" data-dismiss="modal"></button>
                    <button id="btnPrompt2" type="button" class="btn btn-secondary" data-dismiss="modal"></button>
                </div>
            </div>
            <!--/.Content-->
        </div>
    </div>
    <!--Reusable Prompt Modal-->

    <!--Realtime Modals-->
    <!--Ask To Unlock Modal-->
    <div class="modal fade " id="realTimeModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true" data-backdrop="false" style="margin-top: 300px !important;">
        <div class="modal-dialog modal-xl" role="document" style="width:100%">
            <!--Content-->
            <div class="modal-content-full-width modal-content">
                <!--Header-->
                <div class="modal-header" style="background-color: #A8A8A8; border-bottom-width: thick; border-color: #f0ad4e; ">
                    <h4 class="modal-title w-100" id="realTimeTitle" style="color:black; font-size:15px !important;">Realtime Data Row Interface</h4>
                </div>
                <!--Body-->
                <div class="modal-body">
                    <h6 class="modal-title w-100" id="realTimeMessage" style="color:black">This will notify the current user to unlock '<span class="lockedId"></span>'.</h6>
                    <!-- <br>
                    <textarea></textarea>
                    <br>
                    <h6 class="modal-title w-100" id="realTimeInfo" style="color:black"></h6> -->
                </div>
                <!--Footer-->
                <div class="modal-footer" style="background-color: none !important;">
                    <button id="btnAskToUnlock" style="width: auto !important;" type="button" class="btn btn-secondary" data-dismiss="modal">Ask to unlock</button>
                    <button id="btnCancel" type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                </div>
            </div>
            <!--/.Content-->
        </div>
    </div>
    <!--Ask To Unlock Modal-->
    <!--Request To Unlock Modal-->
    <div class="modal fade " id="realTimeRequestModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true" data-backdrop="false" style="margin-top: 300px !important;">
        <div class="modal-dialog modal-xl" role="document" style="width:100%">
            <!--Content-->
            <div class="modal-content-full-width modal-content">
                <!--Header-->
                <div class="modal-header" style="background-color: #A8A8A8; border-bottom-width: thick; border-color: #f0ad4e; ">
                    <h4 class="modal-title w-100" id="realTimeRequestTitle" style="color:black; font-size:15px !important;">Realtime Data Row Interface</h4>
                </div>
                <!--Body-->
                <div class="modal-body">
                    <h6 class="modal-title w-100" id="realTimeRequestMessage" style="color:black">User(s) requesting to unlock:</h6>
                    <table id="tblRequestToUnlock">
                        <thead>
                            <tr>
                                <th>
                                    <span>Booking ID</span>
                                </th>
                                <th>
                                    <span>From Tab</span>
                                </th>
                                <th>
                                    <span>Request By</span>
                                </th>
                                <th>
                                    <span>Actions</span>
                                </th>
                            </tr>
                        </thead>
                        <tbody>
                        </tbody>
                    </table>
                </div>
                <!--Footer-->
                <div class="modal-footer" style="background-color: none !important;">
                    <button id="btnClose" type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                </div>
            </div>
            <!--/.Content-->
        </div>
    </div>
    <!--Request To Unlock Modal-->
    <!--Realtime Modals-->

    <!--Reusable Prompt Dialog-->
    <div class="modal fade " id="promptDialog" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true" data-backdrop="false" style="margin-top: 300px !important;">
        <div class="modal-dialog modal-xl" role="document" style="width:100%">
            <!--Content-->
            <div class="modal-content-full-width modal-content">
                <!--Header-->
                <div class="modal-header" style="background-color: #A8A8A8; border-bottom-width: thick; border-color: #f0ad4e; ">
                    <h4 class="modal-title w-100" id="dialogTitle" style="color:black; font-size:15px !important;"></h4>
                </div>
                <!--Body-->
                <div class="modal-body">
                    <h6 class="modal-title w-100" id="dialogMessage" style="color:black"></h6>
                    <br>
                    <br>
                    <h6 class="modal-title w-100" id="dialogInfo" style="color:black"></h6>
                </div>
                <!--Footer-->
                <div class="modal-footer" style="background-color: none !important;">
                    <button id="btnDialog1" type="button" class="btn btn-secondary" data-dismiss="modal"></button>
                    <button id="btnDialog2" type="button" class="btn btn-secondary" data-dismiss="modal"></button>
                </div>
            </div>
            <!--/.Content-->
        </div>
    </div>
    <!--Reusable Prompt Modal-->

    <!-- Logout Modal-->
    <div class="modal fade " id="logoutModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true" data-backdrop="false" style="margin-top: 300px !important;">
        <div class="modal-dialog modal-xl" role="document" style="width:100%">
            <!--Content-->
            <div class="modal-content-full-width modal-content">
                <!--Header-->
                <div class="modal-header" style="background-color: #A8A8A8; border-bottom-width: thick; border-color: #f0ad4e; ">
                    <h4 class="modal-title w-100" id="myModalLabel" style="color:black; font-size:15px !important;">Logout</h4>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <!--Body-->
                <div class="modal-body">
                    <h6 class="modal-title w-100" id="myModalLabel" style="color:black">Do you want to logout?</h6>
                </div>
                <!--Footer-->
                <div class="modal-footer" style="background-color: none !important;">
                    <button id="btnLogoutConfirm" type="button" class="btn btn-secondary" data-dismiss="modal">Yes</button>
                    <button type="button" class="btn btn-secondary" data-dismiss="modal">No</button>
                </div>
            </div>
            <!--/.Content-->
        </div>
    </div>
    <!-- Logout Modal -->

    <!-- Loading Modal -->
    <div class="modal fade" id="loadModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true" data-backdrop="false">
        <div class="modal-dialog modal-xl" role="document" style="width:400px !important;">
            <!--Content-->
            <div class=" modal-content">
                <!--Header-->
                <div class="modal-header " style="background-color: #A8A8A8; border-bottom-width: thick; border-color: #f0ad4e;">
                </div>
                <!--Body-->

                <div class="text-center  ">
                    <div class="row ">
                        <div class="col-12">
                            <img src="../../../img/wait.gif" width=400 height=100 style=" background-color: none !important;margin-top:0px !important">
                        </div>
                    </div>
                </div>

                <!--Footer-->
                <div class="modal-footer" style="background-color: #A8A8A8; border-bottom-width: thick; border-color: #f0ad4e; padding: 7px !important">
                </div>

                <!--/.Content-->
            </div>
        </div>
    </div>
    <!-- Loading Modal -->

     <!-- Not Valid BN for PV Modal -->
     <div class="modal fade" id="notValidBNForPV" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true" data-backdrop="false" >
      <div class="modal-dialog modal-xl" role="document" style="width:400px !important;" >
        <!--Content-->
        <div class=" modal-content" >
          <!--Header-->
          <div class="modal-header "  style="background-color: #A8A8A8; border-bottom-width: thick; border-color: #f0ad4e;">
          </div>
          <!--Body-->
    
        <div class="text-center  " >
          <h6 id="bnError"></h6>
        </div>  
    
          <!--Footer-->
          <div class="modal-footer"  style="background-color: #A8A8A8; border-bottom-width: thick; border-color: #f0ad4e; padding: 7px !important">
          </div> 
        
        <!--/.Content-->
      </div>
    </div>
  </div>
    <!-- Not Valid BN for PV Modal -->


<<<<<<< HEAD
    <script src="../script/fun.js"></script>
    <script src="../script/addon-pctp-window.js"></script>

=======
  <!-- Custom Modal -->
  <div class="modal fade" id="customModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel" aria-hidden="true" >
    <div class="modal-dialog modal-xl" role="document" style="width:100%">
      <!--Content-->
      <div class="modal-content-full-width modal-content">
        <!--Header-->
        <div class="modal-header"  style="background-color: #A8A8A8; border-bottom-width: thick; border-color: #f0ad4e;">
          <h4 class="modal-title w-100" id="myModalLabel" style="color:black"></h4>
          <button type="button" class="close" data-dismiss="modal" aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
        </div>
        <!--Body-->
        <div class="modal-body">
          <table class="table table-striped table-bordered table-hover" id="tblCustom" style="width:100%; height: 200px;">
          <thead>
            <tr>
              <th style="position: sticky;top: 0;">#</th>
              <th style="position: sticky;top: 0;">Transaction No.</th>
              <th style="position: sticky;top: 0;">Transaction Type</th>
              <th style="position: sticky;top: 0;">Tender</th>
              <th style="position: sticky;top: 0;">From TLG</th>
              <th style="position: sticky;top: 0;">Computed</th>
              <th style="position: sticky;top: 0;">Remarks</th>
            </tr>
          </thead>
          <tbody id="tbodyTally">
            
          </tbody>
        </table>
        </div>
        <!--Footer-->
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
        </div>
      </div>
      <!--/.Content-->
    </div>
  </div>
  <!-- Custom Modal -->
  
<script src="../script/fun.js"></script>
<script src="../script/addon-pctp-window.js"></script>
<!-- <script src="../script/verticalVw.js"></script> -->
<!-- <script src="../script/verticalVwRovic.js"></script>
<script src="../script/verticalVwGabz.js"></script>
<script src="../script/verticalVwKarl.js"></script>
<script src="../script/verticalVwTin.js"></script> -->
  

<?php
//   include 'components/modalVerticalPOD.php';
//   include 'components/modalVerticalBilling.php';
//   include 'components/modalVerticalTP.php';
//   include 'components/modalVerticalPRICING.php';
  include '../../bottom.php' ;
>>>>>>> e9290d2 (issue #36 - corrected node sse url)

    <?php
    include '../../bottom.php'
    ?>

    <?php odbc_close($MSSQL_CONN); ?>