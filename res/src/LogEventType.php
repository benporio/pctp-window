<?php

require_once __DIR__.'/../inc/restriction.php';

enum LogEventType: string {
    case UPDATE = 'UPDATE';
    case CREATE_SO = 'CREATE_SO';
    case CREATE_AR = 'CREATE_AR';
    case CREATE_AP = 'CREATE_AP';
}