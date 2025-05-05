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
package org.oscarehr.managers;

import java.util.List;

import java.util.ArrayList;


import org.oscarehr.common.dao.DemographicPharmacyDao;
import org.oscarehr.common.dao.PharmacyInfoDao;
import org.oscarehr.common.model.DemographicPharmacy;
import org.oscarehr.common.model.PharmacyInfo;
import org.oscarehr.util.LoggedInInfo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import oscar.log.LogAction;

/**
 * Will provide access to pharmacy data.
 * 
 * Future Use: Add privacy, security, and consent profiles
 * 
 *
 */
@Service
public class PharmacyManager {

	//private Logger logger=MiscUtils.getLogger();

	@Autowired
	private DemographicPharmacyDao demographicPharmacyDao;
	@Autowired
	private PharmacyInfoDao pharmacyInfoDao;

	// public PharmacyManager() {
    //     System.out.println("PharmacyManager is initialized.");
    // }

	public List<DemographicPharmacy> getPharmacies(LoggedInInfo loggedInInfo, Integer demographicId) {
		List<DemographicPharmacy> result =  demographicPharmacyDao.findAllByDemographicId(demographicId);
		
		if(result != null) {
			for(DemographicPharmacy item:result) {
		    	//--- log action ---
				LogAction.addLogSynchronous(loggedInInfo, "PharmacyManager.getPharmacies", "pharmacyId="+item.getPharmacyId());
			}
	    }
	    
	    return result;
	}

	public DemographicPharmacy addPharmacy(LoggedInInfo loggedInInfo, Integer demographicId, Integer pharmacyId, Integer preferredOrder) {
		DemographicPharmacy result =  demographicPharmacyDao.addPharmacyToDemographic(demographicId, pharmacyId, preferredOrder);
		
		if(result != null) {
	    	//--- log action ---
			LogAction.addLogSynchronous(loggedInInfo, "PharmacyManager.addPharmacy", "demographicNo="+demographicId+ ",pharmacyId="+pharmacyId);
	    }
	    
	    return result;
	}

	public void removePharmacy(LoggedInInfo loggedInInfo, Integer demographicId, Integer pharmacyId) {
		DemographicPharmacy pharmacy = demographicPharmacyDao.find(pharmacyId);
		if (pharmacy == null) {
			throw new IllegalArgumentException("Unable to locate pharmacy association with id " + pharmacyId);
		}
		
		if (pharmacy.getDemographicNo() != demographicId) {
			throw new IllegalArgumentException("Pharmacy association with id " + pharmacyId + " does't belong to demographic record with ID " + demographicId);
		}
		
		pharmacy.setStatus("0");
		demographicPharmacyDao.saveEntity(pharmacy);
		
		//--- log action ---
		LogAction.addLogSynchronous(loggedInInfo, "PharmacyManager.removePharmacy", "demographicNo="+demographicId + ",pharmacyId="+pharmacyId);	
	}
	
	public PharmacyInfo getPharmacy(LoggedInInfo loggedInInfo, Integer pharmacyId) {
		return pharmacyInfoDao.find(pharmacyId);		
	}

// 	/**
//  * Fetch pharmacies sorted by distance from the user's location.
//  *
//  * @param loggedInInfo Logged-in user information (optional if you need logging)
//  * @param userLat Latitude of the user's entered address
//  * @param userLng Longitude of the user's entered address
//  * @return List of pharmacies sorted by distance
//  */
// public List<PharmacyInfo> getPharmaciesSortedByDistance(LoggedInInfo loggedInInfo, double userLat, double userLng) {
//     System.out.println("getPharmaciesSortedByDistance triggered.");
//     System.out.println("Latitude: " + userLat + ", Longitude: " + userLng);

//     // Check if pharmacyInfoDao is null
//     if (pharmacyInfoDao == null) {
//         System.err.println("pharmacyInfoDao is null in PharmacyManager.");
//         throw new NullPointerException("pharmacyInfoDao is not initialized.");
//     }

//     // Fetch sorted pharmacies using the DAO
//     List<PharmacyInfo> result = pharmacyInfoDao.getPharmaciesSortedByDistance(userLat, userLng);

//     // Check if result is null
//     if (result == null) {
//         System.err.println("DAO returned null for getPharmaciesSortedByDistance.");
//         return new ArrayList<>(); // Return empty list to prevent further errors
//     }

//     // Log results if required
//     if (result.isEmpty()) {
//         System.out.println("No pharmacies found.");
//     } else {
//         for (PharmacyInfo pharmacy : result) {
//             if (pharmacy.getId() == null) {
//                 System.err.println("Pharmacy ID is null for pharmacy: " + pharmacy.getName());
//                 continue; // Skip logging for this pharmacy
//             }
//             LogAction.addLogSynchronous(loggedInInfo, "PharmacyManager.getPharmaciesSortedByDistance",
//                 "pharmacyId=" + pharmacy.getId() + ", distance calculated");
//         }
//     }

//     return result;
// }



}
