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

import java.util.Date;

import javax.persistence.Query;

import org.oscarehr.common.model.CaseManagementTmpSave;
import org.springframework.stereotype.Repository;

@Repository
public class CaseManagementTmpSaveDao extends AbstractDao<CaseManagementTmpSave>{

	//This regex represents the dummy note starter e.g. [30-Mar-2018 .: Tel-Progress Notes]
	private static final String NOTE_TAG_REGEXP = "^\\[[[:digit:]]{2}-[[:alpha:]]{3}-[[:digit:]]{4} \\.\\: [^]]*\\][[:space:]]+$";

	public CaseManagementTmpSaveDao() {
		super(CaseManagementTmpSave.class);
	}
	
    public void remove(String providerNo, Integer demographicNo, Integer programId) {
    	Query query = entityManager.createQuery("DELETE FROM CaseManagementTmpSave x WHERE x.providerNo = ? AND x.demographicNo=? AND x.programId = ?");
		query.setParameter(1, providerNo);
		query.setParameter(2, demographicNo);
		query.setParameter(3, programId);
		query.executeUpdate();
    }

    public CaseManagementTmpSave find(String providerNo, Integer demographicNo, Integer programId) {
    	Query query = entityManager.createQuery("SELECT x FROM CaseManagementTmpSave x WHERE x.providerNo = ? and x.demographicNo=? and x.programId = ? order by x.updateDate DESC");
		query.setParameter(1,providerNo);
		query.setParameter(2,demographicNo);
		query.setParameter(3,programId);
		
		return this.getSingleResultOrNull(query);
    }
    
    public CaseManagementTmpSave find(String providerNo, Integer demographicNo, Integer programId, Date date) {
    	Query query = entityManager.createQuery("SELECT x FROM CaseManagementTmpSave x WHERE x.providerNo = ? and x.demographicNo=? and x.programId = ? and x.updateDate >= ? order by x.updateDate DESC");
		query.setParameter(1,providerNo);
		query.setParameter(2,demographicNo);
		query.setParameter(3,programId);
		query.setParameter(4, date);
		
		return this.getSingleResultOrNull(query);
    }
    
    /**
     * noteHasContent
     * 
     * Identifies whether an encounter note that has been temporarily saved has
     * any significant content, or whether it is either a) empty or b) contains
     * only autogenerated text (e.g. [04-Apr-2018 .: Tel-Progress Note])
     * 
     * @param id the id of the CaseManagementTmpSave object
     * @return true if the note contains significant content, false otherwise
     */
    public boolean noteHasContent(Integer id)
    {
	Query query = entityManager.createNativeQuery("SELECT * FROM casemgmt_tmpsave x WHERE x.id = ? and x.note  NOT REGEXP ? order by x.update_date DESC", CaseManagementTmpSave.class);

	query.setParameter(1, id);
	query.setParameter(2, NOTE_TAG_REGEXP);

	return (this.getSingleResultOrNull(query) != null);
    }
}
