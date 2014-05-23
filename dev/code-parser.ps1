cat .\codes.txt | foreach {
    $code, $name, $origin, $arg, $desc = $_ -split "`t";
    if ($desc) { $desc = " $desc" }
    if (!$origin) { $origin = "Unknown" }
    "# $code $arg`n#$desc [$origin]`n$code = '$name';`n" }