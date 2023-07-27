<style>
    .spinner {
        position: fixed;
        left: 52%;
        top: 39%;
        height: 160px;
        width: 160px;
        margin: 0px auto;
        -webkit-animation: rotation .6s infinite linear;
        -moz-animation: rotation .6s infinite linear;
        -o-animation: rotation .6s infinite linear;
        animation: rotation .6s infinite linear;
        border-left: 16px solid rgba(0, 174, 239, .15);
        border-right: 16px solid rgba(0, 174, 239, .15);
        border-bottom: 16px solid rgba(0, 174, 239, .15);
        border-top: 16px solid rgba(0, 174, 239, .8);
        border-radius: 100%;
    }

    @-webkit-keyframes rotation {
        from {
            -webkit-transform: rotate(0deg);
        }

        to {
            -webkit-transform: rotate(359deg);
        }
    }

    @-moz-keyframes rotation {
        from {
            -moz-transform: rotate(0deg);
        }

        to {
            -moz-transform: rotate(359deg);
        }
    }

    @-o-keyframes rotation {
        from {
            -o-transform: rotate(0deg);
        }

        to {
            -o-transform: rotate(359deg);
        }
    }

    @keyframes rotation {
        from {
            transform: rotate(0deg);
        }

        to {
            transform: rotate(359deg);
        }
    }

    @keyframes color-change {
        0% {
            color: red;
        }

        50% {
            color: blue;
        }

        100% {
            color: red;
        }
    }

    .exclude-check {
        -webkit-appearance: initial;
        appearance: initial;
        width: 25px;
        height: 25px;
        border: none;
        background: lightgray;
        position: relative;
    }

    .exclude-check:checked {
        background: red;
    }

    .exclude-check:checked:after {
        /* Heres your symbol replacement - this is a tick in Unicode. */
        content: "\1F5D9";
        color: white;
        /* The following positions my tick in the center, 
     * but you could just overlay the entire box
     * with a full after element with a background if you want to */
        position: absolute;
        left: 50%;
        top: 50%;
        -webkit-transform: translate(-50%, -50%);
        -moz-transform: translate(-50%, -50%);
        -ms-transform: translate(-50%, -50%);
        transform: translate(-50%, -50%);
        /*
     * If you want to fully change the check appearance, use the following:
     * content: " ";
     * width: 100%;
     * height: 100%;
     * background: blue;
     * top: 0;
     * left: 0;
     */
    }
</style>
<div id="loadingAnimation" class="spinner"></div>