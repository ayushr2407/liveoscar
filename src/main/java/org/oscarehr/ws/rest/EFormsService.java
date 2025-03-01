/**
 * Copyright (c) 2001-2002. Department of Family Medicine, McMaster University. All Rights Reserved.
 * This software is published under the GPL GNU General Public License.
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * This software was written for the
 * Department of Family Medicine
 * McMaster University
 * Hamilton
 * Ontario, Canada
 */

package org.oscarehr.ws.rest;

import org.apache.logging.log4j.Logger;
import org.oscarehr.util.MiscUtils;
import org.oscarehr.common.dao.EFormDao;
import org.oscarehr.managers.FormsManager;
import org.oscarehr.ws.rest.conversion.EFormConverter;
import org.oscarehr.ws.rest.response.RestResponse;
import org.oscarehr.ws.rest.to.model.EFormTo1;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import oscar.OscarProperties;
import oscar.eform.EFormLoader;
import oscar.eform.actions.DisplayImageAction;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import java.io.File;
import java.util.Collections;
import java.util.List;

@Path("/eforms")
@Component("EFormsService")
public class EFormsService extends AbstractServiceImpl
{
	Logger logger = MiscUtils.getLogger();

	@Autowired
	private FormsManager formsManager;

	/**
	 * retrieves a list of all EForms better than the getAllEFormNames method
	 * EForm responses will not contain the eform html
	 * @return RestResponse
	 */
	@GET
	@Path("/")
	@Produces(MediaType.APPLICATION_JSON)
	public RestResponse<List<EFormTo1>> getEFormList()
	{
		List<EFormTo1> allEforms = new EFormConverter(true).getAllAsTransferObjects(getLoggedInInfo(),
				formsManager.findByStatus(getLoggedInInfo(), true, EFormDao.EFormSortOrder.NAME));
		return RestResponse.successResponse(allEforms);
	}

	/**
	 * retrieves a list of all EForm image names as strings
	 * @return RestResponse
	 */
	@GET
	@Path("/images")
	@Produces(MediaType.APPLICATION_JSON)
	public RestResponse<List<String>> getEFormImageList()
	{
		String imageHomeDir = OscarProperties.getInstance().getProperty("eform_image");
		File directory = new File(imageHomeDir);

		List<String> imagesNames = DisplayImageAction.getFiles(directory, ".*\\.(jpg|jpeg|png|gif)$", null);
		Collections.sort(imagesNames);
		return RestResponse.successResponse(imagesNames);
	}

	/**
	 * retrieves a list of all EForm database tags
	 * @return RestResponse
	 */
	@GET
	@Path("/databaseTags")
	@Produces(MediaType.APPLICATION_JSON)
	public RestResponse<List<String>> getEFormDatabaseTagList()
	{
		List<String> dbTagList;
		try
		{
			EFormLoader loader = EFormLoader.getInstance();
			dbTagList = loader.getNames();
		}
		catch(Exception e)
		{
			logger.error("DB tag Error: ", e);
			return RestResponse.errorResponse("Error retrieving oscar database tag list");
		}
		return RestResponse.successResponse(dbTagList);
	}
}