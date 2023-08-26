param(
    [Parameter(Mandatory=$true)]
    [string]$file
)

# Read the file from given path
$idStrings = Get-Content -Path $file

# Initialize array
$sw_values = @()
$linesep = "`n"

foreach ($line in $idStrings) {
    # Only process lines starting with 735
    if ($line -match "^(735)") {
        $tokens = $line.Split(",")
        $sw_values += "('$($tokens[0].Trim())', '$($tokens[1].Trim())'),$linesep"
    }
}

# Remove the last comma and newline
$sw_values[-1] = $sw_values[-1].TrimEnd(",`n")
$sw_values[-1] += ";"

# Construct the SQL
$sqlTempTable = @"
CREATE TEMPORARY TABLE temp_sw_update(
    device_id VARCHAR(255),
    sw_version VARCHAR(255)
);
INSERT INTO temp_sw_update (device_id, sw_version) VALUES
$sw_values

UPDATE softaversio
SET sw_version = temp_sw_update.sw_version
FROM temp_sw_update
WHERE softaversio.device_id = temp_sw_update.device_id;

DROP TABLE temp_sw_update;
"@

# Output the SQL
$sqlTempTable