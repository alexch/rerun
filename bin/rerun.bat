:: %~dp0 means "the directory of the current script file"
:: see https://stackoverflow.com/questions/17063947/get-current-batchfile-directory
ruby %~dp0\rerun %*
