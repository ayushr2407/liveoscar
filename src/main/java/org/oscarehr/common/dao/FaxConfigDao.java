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
package org.oscarehr.common.dao;

import java.util.List;
import javax.persistence.Query;

import org.oscarehr.common.model.FaxConfig;
import org.springframework.stereotype.Repository;

@Repository
public class FaxConfigDao extends AbstractDao<FaxConfig> {

    public FaxConfigDao() {
        super(FaxConfig.class);
    }

    public FaxConfig getConfigByNumber(String number) {
        Query query = entityManager.createQuery("SELECT config FROM FaxConfig config WHERE config.faxNumber = :number");
        query.setParameter("number", number);
        return getSingleResultOrNull(query);
    }

    // Add this method to get all fax configurations
	@SuppressWarnings("unchecked")
	public List<FaxConfig> getAllConfigurations() {
		Query query = entityManager.createQuery("SELECT config FROM FaxConfig config");
		return (List<FaxConfig>) query.getResultList();
	}

    // Add this method to delete a configuration by ID
    public void deleteConfiguration(Integer id) {
        FaxConfig config = find(id);
        if (config != null) {
            remove(config);
        }
    }

    // If you need a method to find a configuration by ID, add this
    public FaxConfig findById(Integer id) {
        return find(id);
    }
    public FaxConfig findActive() {
        Query query = entityManager.createQuery("FROM FaxConfig WHERE active = :activeStatus");
        query.setParameter("activeStatus", true);
        return getSingleResultOrNull(query);
    }
}


// import javax.persistence.Query;

// import org.oscarehr.common.model.FaxConfig;
// import org.springframework.stereotype.Repository;

// @Repository
// public class FaxConfigDao extends AbstractDao<FaxConfig> {

// 	public FaxConfigDao() {		
//     	super(FaxConfig.class);
//     }


// 	public FaxConfig getConfigByNumber(String number) {
// 		Query query = entityManager.createQuery("select config from FaxConfig config where config.faxNumber = :number");
		
// 		query.setParameter("number", number);
		
// 		return getSingleResultOrNull(query);
// 	}
// }
