<?php

require_once __DIR__.'/../inc/restriction.php';

interface IAction {
    function echo(): string;
}