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

import java.util.Collections;
import java.util.List;

import javax.persistence.Query;

import org.oscarehr.common.model.DemographicContact;
import org.springframework.stereotype.Repository;

@Repository
public class DemographicContactDao extends AbstractDao<DemographicContact>{

	public DemographicContactDao() {
		super(DemographicContact.class);
	}

	public List<DemographicContact> findByDemographicNo(int demographicNo) {
		String sql = "select x from " + this.modelClass.getName() + " x where x.demographicNo=? and x.deleted=false";
		Query query = entityManager.createQuery(sql);
		query.setParameter(1, demographicNo);
		@SuppressWarnings("unchecked")
		List<DemographicContact> dContacts = query.getResultList();
		return dContacts;
	}
	
	public List<DemographicContact> findActiveByDemographicNo(int demographicNo) {
		String sql = "select x from " + this.modelClass.getName() + " x where x.demographicNo=? and x.deleted=false and x.active=1";
		Query query = entityManager.createQuery(sql);
		query.setParameter(1, demographicNo);
		@SuppressWarnings("unchecked")
		List<DemographicContact> dContacts = query.getResultList();
		return dContacts;
	}

	public List<DemographicContact> findAllByDemographicNo(Integer demographicNo) {
		String sql = "select x from " + this.modelClass.getName() + " x where x.demographicNo=? and x.deleted = false";
		Query query = entityManager.createQuery(sql);
		query.setParameter(1, demographicNo);
		@SuppressWarnings("unchecked")
		List<DemographicContact> dContacts = query.getResultList();
		return dContacts;
	}


	public List<DemographicContact> findInactiveByDemographicNo(Integer demographicNo) {
		String sql = "select x from " + this.modelClass.getName() + " x where x.demographicNo=? and x.deleted = false and x.active = 0";
		Query query = entityManager.createQuery(sql);
		query.setParameter(1, demographicNo);
		@SuppressWarnings("unchecked")
		List<DemographicContact> dContacts = query.getResultList();
		return dContacts;
	}
	
	public List<DemographicContact> findByDemographicNoAndCategory(int demographicNo,String category) {
		String sql = "select x from " + this.modelClass.getName() + " x where x.demographicNo=? and x.category=? and x.deleted=false";
		Query query = entityManager.createQuery(sql);
		query.setParameter(1, demographicNo);
		query.setParameter(2, category);
		@SuppressWarnings("unchecked")
		List<DemographicContact> dContacts = query.getResultList();
		return dContacts;
	}

	public List<DemographicContact> findByDemographicNoAndCategoryOnHealthCareTeam(int demographicNo,String category, Boolean onHealthCareTeam) {
		String sql = "select x from " + this.modelClass.getName() + " x where x.demographicNo=? and x.category=? and x.deleted=false and x.healthCareTeam=?";
		Query query = entityManager.createQuery(sql);
		query.setParameter(1, demographicNo);
		query.setParameter(2, category);
		query.setParameter(3, onHealthCareTeam);
		@SuppressWarnings("unchecked")
		List<DemographicContact> dContacts = query.getResultList();
		return dContacts;
	}
	
    public List<DemographicContact> findActiveByDemographicNoAndCategoryAndType(int demographicNo, String category, int contactType) {
        String sql = "SELECT x FROM " + this.modelClass.getName() + 
                " x WHERE x.demographicNo = :demographicNo AND x.category = :category " +
                "AND x.type = :contactType AND x.active = 1 AND x.deleted = 0";
        Query query = entityManager.createQuery(sql);
        query.setParameter("demographicNo", demographicNo);
        query.setParameter("category", category);
        query.setParameter("contactType", contactType);
        @SuppressWarnings("unchecked")
        List<DemographicContact> dContacts = query.getResultList();
        return dContacts;
    }
    
    public List<DemographicContact> findActiveSubstituteDecisionMaker(Integer demographicNo) {
		String sql = "select x from " + this.modelClass.getName() + " x where x.demographicNo=? and x.deleted=false and x.active=1 and x.type=1 and x.sdm='true'";
		Query query = entityManager.createQuery(sql);
		query.setParameter(1, demographicNo);
		@SuppressWarnings("unchecked")
		List<DemographicContact> dContacts = query.getResultList();
		return dContacts;
		
	}

	public List<DemographicContact> find(int demographicNo, int contactId) {
		String sql = "select x from " + this.modelClass.getName() + " x where x.demographicNo=? and x.contactId = ? and x.deleted=false";
		Query query = entityManager.createQuery(sql);
		query.setParameter(1, demographicNo);
		query.setParameter(2, new Integer(contactId).toString());
		@SuppressWarnings("unchecked")
		List<DemographicContact> dContacts = query.getResultList();
		return dContacts;
	}
	
	public List<DemographicContact> findAllByContactIdAndCategoryAndType(int contactId, String category, int type) {
		String sql = "select x from " + this.modelClass.getName() + " x where x.contactId = ? and x.category = ? and x.type = ?";
		Query query = entityManager.createQuery(sql);
		query.setParameter(1, new Integer(contactId).toString());
		query.setParameter(2, category);
		query.setParameter(3, type);
		
		@SuppressWarnings("unchecked")
		List<DemographicContact> dContacts = query.getResultList();
		return dContacts;
	}
	
	public List<DemographicContact> findAllByDemographicNoCategoryAndRole(Integer demographicNo, String category, String role) {
		String sql = "SELECT x FROM " + this.modelClass.getName() + " x WHERE x.demographicNo = :demographicNo AND x.category = :category AND x.role = :role AND x.deleted = FALSE";
		Query query = entityManager.createQuery(sql);
		query.setParameter("demographicNo", demographicNo);
		query.setParameter("category", category);
		query.setParameter("role", role);

		@SuppressWarnings("unchecked")
		List<DemographicContact> dContacts = query.getResultList();
		return dContacts;
	}

// added back in some missing

	public List<DemographicContact> findAllByDemographicNoAndCategoryAndType(int demographicNo, String category, int type) {
		String sql = "select x from " + this.modelClass.getName() + " x where x.demographicNo = ? and x.category = ? and x.type = ? and x.active=1 and deleted=false";
		Query query = entityManager.createQuery(sql);
		query.setParameter(1, demographicNo);
		query.setParameter(2, category);
		query.setParameter(3, type);
		
		@SuppressWarnings("unchecked")
		List<DemographicContact> dContacts = query.getResultList();
		if(dContacts == null) {
			dContacts = Collections.emptyList();
		}
		return dContacts;
	}


	public List<DemographicContact> findSDMByDemographicNo(int demographicNo) {
		String sql = "select x from " + this.modelClass.getName() + " x where x.demographicNo = ? and x.sdm = 'true'  and x.active=1 and deleted=false";
		Query query = entityManager.createQuery(sql);
		query.setParameter(1, demographicNo);
		
		@SuppressWarnings("unchecked")
		List<DemographicContact> dContacts = query.getResultList();
		if(dContacts == null) {
			dContacts = Collections.emptyList();
		}
		return dContacts;
	}

}
