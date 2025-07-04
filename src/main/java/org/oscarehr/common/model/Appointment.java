/**
 *
 * Copyright (c) 2005-2012. Centre for Research on Inner City Health, St. Michael's Hospital, Toronto. All Rights Reserved.
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
 * This software was written for
 * Centre for Research on Inner City Health, St. Michael's Hospital,
 * Toronto, Ontario, Canada
 */

package org.oscarehr.common.model;

import java.io.Serializable;
import java.util.Calendar;
import java.util.Comparator;
import java.util.Date;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.EnumType;
import javax.persistence.Enumerated;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.PrePersist;
import javax.persistence.PreUpdate;
import javax.persistence.Table;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;

@Entity
@Table(name = "appointment")
public class Appointment extends AbstractModel<Integer> implements Serializable, DemographicData {

	public enum BookingSource
	{
		OSCAR,
		MYOSCAR_SELF_BOOKING
	}
	
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	@Column(name = "appointment_no")
	private Integer id;

	@Column(name = "provider_no")
	private String providerNo;

	@Temporal(TemporalType.DATE)
	@Column(name = "appointment_date")
	private Date appointmentDate;

	@Temporal(TemporalType.TIME)
	@Column(name = "start_time")
	private Date startTime;

	@Temporal(TemporalType.TIME)
	@Column(name = "end_time")
	private Date endTime;

	private String name;

	@Column(name = "demographic_no")
	private int demographicNo;

	@Column(name = "program_id")
	private int programId;

	private String notes;
	private String reason;
	private String location;

	//Resources entity used for saving mode(deliver/pickup) only the column name has been changed to deliveryMethod
	@Column(name = "deliveryMethod")
	private String resources;
	
	private String type;
	private String style;
	private String billing;
	private String status = "t";

	@Column(name = "imported_status")
	private String importedStatus;

	@Temporal(TemporalType.TIMESTAMP)
	@Column(name = "createdatetime")
	private Date createDateTime = new Date();

	@Temporal(TemporalType.TIMESTAMP)
	@Column(name = "updatedatetime")
	private Date updateDateTime = new Date();

	private String creator;

	@Column(name = "lastupdateuser")
	private String lastUpdateUser;

	private String remarks;
	private String urgency;
	private Integer creatorSecurityId;
	
	@Enumerated(EnumType.STRING)
	private BookingSource bookingSource;
	
	private Integer reasonCode;

    public Appointment() {
    }

    public Appointment(Appointment a) {
        this.id = a.getId();
        this.providerNo = a.getProviderNo();
        this.appointmentDate = a.getAppointmentDate();
        this.startTime = a.getStartTime();
        this.endTime = a.getEndTime();
        this.name = a.getName();
        this.demographicNo = a.getDemographicNo();
        this.programId = a.getProgramId();
        this.notes = a.getNotes();
        this.reason = a.getReason();
        this.location = a.getLocation();
        this.resources = a.getResources();
        this.type = a.getType();
        this.style = a.getStyle();
        this.billing = a.getBilling();
        this.status = a.getStatus();
        this.importedStatus = a.getImportedStatus();
        this.createDateTime = a.getCreateDateTime();
        this.updateDateTime = a.getUpdateDateTime();
        this.creator = a.getCreator();
        this.lastUpdateUser = a.getLastUpdateUser();
        this.remarks = a.getRemarks();
        this.urgency = a.getUrgency();
        this.creatorSecurityId = a.getCreatorSecurityId();
        this.bookingSource = a.getBookingSource();
        this.reasonCode = a.getReasonCode();
    }

    public Integer getReasonCode() {
		return reasonCode;
	}

	public void setReasonCode(Integer reasonCode) {
		this.reasonCode = reasonCode;
	}

	public String getProviderNo() {
		return providerNo;
	}

	public void setProviderNo(String providerNo) {
		this.providerNo = providerNo;
	}

	public Date getAppointmentDate() {
		return appointmentDate;
	}

	public void setAppointmentDate(Date appointmentDate) {
		this.appointmentDate = appointmentDate;
	}

	public Date getStartTime() {
		return startTime;
	}

	public void setStartTime(Date startTime) {
		this.startTime = startTime;
	}

	public Date getEndTime() {
		return endTime;
	}

	public void setEndTime(Date endTime) {
		this.endTime = endTime;
	}
	
	public String getDuration(){
		String ret="";
		
		long diff = endTime.getTime() - startTime.getTime();
		long diffMinutes = diff / (60 * 1000) % 60;         
		long diffHours = diff / (60 * 60 * 1000);
		
		if(diffHours > 0) ret += (int)diffHours + "H "; 
		if(diffMinutes > 0) ret += (int)diffMinutes + "m ";
		
		return ret;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public int getDemographicNo() {
		return demographicNo;
	}

	public void setDemographicNo(int demographicNo) {
		this.demographicNo = demographicNo;
	}

	public int getProgramId() {
		return programId;
	}

	public void setProgramId(int programId) {
		this.programId = programId;
	}

	public String getNotes() {
		return notes;
	}

	public void setNotes(String notes) {
		this.notes = notes;
	}

	public String getReason() {
		return reason;
	}

	public void setReason(String reason) {
		this.reason = reason;
	}

	public String getLocation() {
		return location;
	}

	public void setLocation(String location) {
		this.location = location;
	}

	public String getResources() {
		return resources;
	}

	public void setResources(String resources) {
		this.resources = resources;
	}

	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}

	public String getStyle() {
		return style;
	}

	public void setStyle(String style) {
		this.style = style;
	}

	public String getBilling() {
		return billing;
	}

	public void setBilling(String billing) {
		this.billing = billing;
	}

	public String getStatus() {
		return status;
	}

	public void setStatus(String status) {
		this.status = status;
	}

	public Date getCreateDateTime() {
		return createDateTime;
	}

	public void setCreateDateTime(Date createDateTime) {
		this.createDateTime = createDateTime;
	}

	public Date getUpdateDateTime() {
		return updateDateTime;
	}

	public void setUpdateDateTime(Date updateDateTime) {
		this.updateDateTime = updateDateTime;
	}

	public String getCreator() {
		return creator;
	}

	public void setCreator(String creator) {
		this.creator = creator;
	}

	public String getLastUpdateUser() {
		return lastUpdateUser;
	}

	public void setLastUpdateUser(String lastUpdateUser) {
		this.lastUpdateUser = lastUpdateUser;
	}

	public String getRemarks() {
		return remarks;
	}

	public void setRemarks(String remarks) {
		this.remarks = remarks;
	}

	public String getImportedStatus() {
		return (importedStatus);
	}

	public void setImportedStatus(String importedStatus) {
		this.importedStatus = importedStatus;
	}

	public String getUrgency() {
		return (urgency);
	}

	public void setUrgency(String urgency) {
		this.urgency = urgency;
	}

	public Integer getCreatorSecurityId() {
    	return (creatorSecurityId);
    }

	public void setCreatorSecurityId(Integer creatorSecurityId) {
    	this.creatorSecurityId = creatorSecurityId;
    }

	public BookingSource getBookingSource() {
    	return (bookingSource);
    }

	public void setBookingSource(BookingSource bookingSource) {
    	this.bookingSource = bookingSource;
    }

	@Override
	public Integer getId() {
		return id;
	}
	
	public void setId(Integer id) {
		this.id = id;
	}

	@PrePersist
	@PreUpdate
	protected void jpaUpdateLastUpdateTime() {
		this.updateDateTime = new Date();
	}
	
    public static final Comparator<Appointment> APPT_DATE_COMPARATOR =new Comparator<Appointment>()
    {
        public int compare(Appointment o1, Appointment o2) {
        	if (o1==null && o2!=null) return -1;
        	if (o1==null && o2==null) return 0;
        	if (o1!=null && o2==null) return 1;
        					
        	Date d1 = o1.getAppointmentDate();
        	Date d2 = o2.getAppointmentDate();
        	int tmp = d1.compareTo(d2);
        	if(tmp == 0) {
        		Date t1 = o1.getStartTime();
        		Date t2 = o2.getStartTime();
        		return t1.compareTo(t2);
        	} else {
        		return tmp;
        	}     
        }       
    };


   
   public Date getStartTimeAsFullDate(){
	   try{
		   Calendar cal = Calendar.getInstance();
		   cal.setTime(getAppointmentDate());
		   Calendar acal = Calendar.getInstance();
		   acal.setTime(getStartTime());
		   cal.set(Calendar.HOUR_OF_DAY, acal.get(Calendar.HOUR_OF_DAY));
		   cal.set(Calendar.MINUTE, acal.get(Calendar.MINUTE));
		   cal.set(Calendar.SECOND,0);
		   cal.set(Calendar.MILLISECOND, 0);
		   return cal.getTime();
	   }catch(Exception e){
		   return null;
	   }
   }
    public Date getEndTimeAsFullDate(){
        try{
            Calendar cal = Calendar.getInstance();
            cal.setTime(getAppointmentDate());
            Calendar acal = Calendar.getInstance();
            acal.setTime(getEndTime());
            cal.set(Calendar.HOUR_OF_DAY, acal.get(Calendar.HOUR_OF_DAY));
            cal.set(Calendar.MINUTE, acal.get(Calendar.MINUTE));
            cal.set(Calendar.SECOND,0);
            cal.set(Calendar.MILLISECOND, 0);
            return cal.getTime();
        }catch(Exception e){
            return null;
        }
    }
    
}
