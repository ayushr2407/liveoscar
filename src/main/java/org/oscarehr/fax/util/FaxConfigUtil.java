package org.oscarehr.fax.util;

import org.oscarehr.common.dao.FaxConfigDao;
import org.oscarehr.common.model.FaxConfig;
import org.oscarehr.util.SpringUtils;

public class FaxConfigUtil {
    public static FaxConfig getActiveFaxConfig() {
        FaxConfigDao faxConfigDao = SpringUtils.getBean(FaxConfigDao.class);
        return faxConfigDao.findActive();
    }
}