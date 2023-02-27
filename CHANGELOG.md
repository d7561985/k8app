# Changelog

## app

### 3.1.9
* EFS implementation

### 3.1.6
* toleration for deployment
### 3.1.5
* fix resources with partial implementation

### 3.1.4
* tel variable VERSION support

### 3.1.3
* deployment: resources request/limits 


### 3.1.2
* deployment: lifecycle option moved to values. Because our distress doesn't have any sleep command we should consider dont use it as hardcode

### 3.1.1
* deployment: set `revisionHistoryLimit: 1` ToDo: move to values 

### 3.1.0
* trigger pods to restart when only config file or secrets was changed. Allow reconcile changes with already on-live services.

### 3.0.8, 3.0.9
* cronjob fix
* this crd appload when tag is number

### 3.0.6, 3.0.7
* documentation
* volume mounts
 
### 3.0.5
* worker bug fix

### 3.0.4
* `commands` and `args` commands 

### 3.0.3
* secrets should redeploy every new secret changes or when tag is changed
* example values, min working values 
