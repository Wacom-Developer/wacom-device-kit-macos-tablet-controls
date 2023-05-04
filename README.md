# Readme

## Introduction
Tablet Controls is an application that demonstrates how to retrieve tablet control information from Wacom Tablet Driver using Apple Events.

## Application Details
The application uses the functions described in the [Driver Request Interface - Reference](https://developer-docs.wacom.com/intuos-cintiq-business-tablets/docs/dri-reference)
 documentation to communicate with the tablet driver. Data from the tablet arrives by NSDistributedNotifications. The keys to access the data in the returned Notification Dictionary are found in TabletAEDictionary.h.

You can download the Tablet Controls sample code and view the inline comments to find out detailed information about the sample code itself.

All Wacom tablets supported by the Wacom driver are supported by this API. Get the tablet driver that supports your device at: https://www.wacom.com/support/product-support/drivers.

## See Also  

The Driver Interface Request developer documentation has complete API details:

[Driver Request Interface - Basics](https://developer-docs.wacom.com/intuos-cintiq-business-tablets/docs/dri-basics)

[Driver Request Interface - Reference](https://developer-docs.wacom.com/intuos-cintiq-business-tablets/docs/dri-reference)

[Driver Request Interface - FAQs](https://developer-support.wacom.com/hc/en-us/articles/12845119756055)
  


## Where To Get Help
If you have questions about this demo please visit our support page: https://developer.wacom.com/developer-dashboard/support. 

## License
This sample code is licensed under the MIT License: https://choosealicense.com/licenses/mit/

