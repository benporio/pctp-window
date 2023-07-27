<?php

require_once __DIR__.'/../inc/restriction.php';

enum TabAccessType: string {
    case NONE = 'NONE';
    case VIEW = 'VIEW';
    case FULL = 'FULL';
}
