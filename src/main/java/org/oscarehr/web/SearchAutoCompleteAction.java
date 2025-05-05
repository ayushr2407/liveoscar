package org.oscarehr.web;

import org.oscarehr.common.dao.DemographicDao;
import org.oscarehr.common.model.Demographic;
import org.oscarehr.util.SpringUtils;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.util.*;
import org.apache.struts.action.Action;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;
import com.fasterxml.jackson.databind.ObjectMapper;

public class SearchAutoCompleteAction extends Action {

    private static final int MAX_RESULTS = 15;

    @Override
    public ActionForward execute(ActionMapping mapping, ActionForm form,
                                 HttpServletRequest request, HttpServletResponse response) throws Exception {

        String keyword = request.getParameter("keyword");
        if (keyword == null || keyword.trim().isEmpty()) {
            return null;
        }

        DemographicDao demoDao = (DemographicDao) SpringUtils.getBean("demographicDao");

        List<Demographic> matches = new ArrayList<>();
        keyword = keyword.trim();

        if (keyword.matches("\\d+")) {
            // Search by HIN if keyword is digits only
            matches = demoDao.searchDemographicByHIN(keyword, MAX_RESULTS, 0, null, true);
        } else {
            // Search by name
            matches = demoDao.searchDemographicByNameString(keyword, 0, MAX_RESULTS);
        }

        List<Map<String, Object>> results = new ArrayList<>();
        for (Demographic d : matches) {
            Map<String, Object> map = new HashMap<>();
            map.put("id", d.getDemographicNo());
            map.put("name", d.getLastName() + ", " + d.getFirstName());
            map.put("hin", d.getHin());
            results.add(map);
        }

        response.setContentType("application/json");
        new ObjectMapper().writeValue(response.getWriter(), results);
        return null; // No forward, direct JSON response
    }
}
// homepage searchbox for patient (name and PHN)