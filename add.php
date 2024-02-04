<?php

/**
 * @param string $fileName
 *
 * @return array
 */
function readToVariable(string $fileName): array
{
    return include $fileName;
}

/**
 * @param array $useArray
 * @param array $useKeys
 * @param mixed $useValue
 *
 * @return array
 */
function addDeepValue(array $useArray, array $useKeys, $useValue): array
{
    if (count($useKeys) > 1) {
        $key = array_shift($useKeys);

        if ($key === '[]') {
            $key = count($useArray);
        }

        $array = array_key_exists($key, $useArray) ? $useArray[ $key ] : [];

        $useArray[ $key ] = addDeepValue($array, $useKeys, $useValue);
    } else {
        $key = array_shift($useKeys);

        if (is_string($useValue) && preg_match('/^\{/', trim($useValue))) {
            $useValue = json_decode(trim($useValue), JSON_OBJECT_AS_ARRAY);
        }

        if ($key === '[]') {
            $useArray[] = $useValue;
        } else {
            $useArray[ $key ] = $useValue;
        }
    }

    return $useArray;
}

/**
 * @param mixed  $variable
 * @param string $indent
 *
 * @return string|null
 */
function varExport($variable, string $indent = ""): string
{
    switch (gettype($variable)) {
        case 'string':
            return '\'' . addcslashes($variable, "\\\$\"\r\n\t\v\f") . '\'';
        case 'array':
            $indexed = array_keys($variable) === range(0, count($variable) - 1);
            $r = [];
            foreach ($variable as $key => $value) {
                $r[] = "$indent    " . ($indexed ? '' : varExport($key) . ' => ') . varExport($value, "$indent    ");
            }
            return "[\n" . implode(",\n", $r) . "\n" . $indent . ']';
        case 'boolean':
            return $variable ? 'TRUE' : 'FALSE';
        default:
            return var_export($variable, true);
    }
}

if ( ! array_key_exists(1, $argv)) {
    echo "No path to configuration specified!\n";
    die(1);
}

if ( ! array_key_exists(2, $argv)) {
    echo "No key specified!\n";
    die(1);
}

if ( ! array_key_exists(3, $argv)) {
    echo "No value specified!\n";
    die(1);
}

$magento2ConfigFile = trim($argv[ 1 ]);
$key = trim($argv[ 2 ]);
$value = trim($argv[ 3 ]);

if (file_exists($magento2ConfigFile) && is_dir($magento2ConfigFile)) {
    $keys = explode('/', $key);
    $firstKey = array_shift($keys);

    $magento2ConfigFile = sprintf('%s/%s', $magento2ConfigFile, $firstKey === 'system' ? 'config.php' : 'env.php');
}

if ( ! file_exists($magento2ConfigFile) || ! is_writable($magento2ConfigFile)) {
    echo sprintf("Configuration file not writeable at: %s\n", $magento2ConfigFile);
    exit(1);
}

echo "Reading configuration file: $magento2ConfigFile\n";
$configuration = readToVariable($magento2ConfigFile);

if ($value === 'true') {
    $value = true;
} else if ($value === 'false') {
    $value = false;
}

echo "Adding key: $key\n";
$configuration = addDeepValue($configuration, explode('/', $key), $value);

echo "Writing configuration file: $magento2ConfigFile\n";
file_put_contents($magento2ConfigFile, "<?php\nreturn " . varExport($configuration) . ';');
