<?php

spl_autoload_register(function($className) {
    $path = __DIR__.'/../src';
    $mainDir = scandir($path);
    foreach($mainDir as $dir) {
        if (is_dir($path."\\$dir")) {
            $fullPath = $path."\\$dir";
            $file = "$fullPath\\$className.php";
                $file = str_replace('\\', DIRECTORY_SEPARATOR, $file);
                if (file_exists($file)) {
                    include $file;
                }
        }
    }
});

?>