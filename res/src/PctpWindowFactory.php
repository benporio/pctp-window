<?php

require_once __DIR__.'/../inc/restriction.php';

final class PctpWindowFactory
{
    private static array $sessionClassKeys = [];

    private function __construct(){}
    
    private static function checkSession()
    {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
    }

    private static function accessSessionClassKeys(array $sessions = null): array
    {
        if ((bool)$sessions) {
            if (isset($sessions['session_class_keys'])) {
                return (array) json_decode($sessions['session_class_keys']);
            } else {
                return [];
            }
        } else {
            if (isset($_SESSION['session_class_keys'])) {
                return (array) json_decode($_SESSION['session_class_keys']);
            } else {
                return [];
            }
        }
    }

    private static function storeObjectWithKey(ASerializableClass $object, bool $isNew)
    {
        self::$sessionClassKeys = self::accessSessionClassKeys();
        if (!$isNew) {
            $key = array_search(get_class($object), self::$sessionClassKeys);
            if ($key) {
                $_SESSION[$key] = serialize($object);
            } else {
                $isNew = true;
            }
        }
        if ($isNew) {
            $key = get_class($object).time();
            self::$sessionClassKeys[$key] = get_class($object);
            $_SESSION[$key] = serialize($object);
            $_SESSION['session_class_keys'] = json_encode(self::$sessionClassKeys);
        }
    }

    final public static function getObject(string $className, array $sessions = null): mixed
    {
        try {
            if ((bool)$sessions) {
                self::$sessionClassKeys = self::accessSessionClassKeys($sessions);
                $key = array_search($className, self::$sessionClassKeys);
                if (isset($sessions[$key])) {
                    if (count((array)@unserialize($sessions[$key])) === 0) {
                        return null;
                    }
                    return unserialize($sessions[$key]);
                }
            } else {
                self::checkSession();
                self::$sessionClassKeys = self::accessSessionClassKeys();
                $key = array_search($className, self::$sessionClassKeys);
                if (isset($_SESSION[$key])) {
                    if (count((array)@unserialize($_SESSION[$key])) === 0) {
                        return null;
                    }
                    return unserialize($_SESSION[$key]);
                }
            }
            return null;
        } catch (\Throwable $th) {
            return null; 
        } 
    }

    final public static function storeObject(ASerializableClass $object, bool $isNew = false)
    {
        self::checkSession();
        if ($object !== null) {
            self::storeObjectWithKey($object, $isNew);
        }
    }
}