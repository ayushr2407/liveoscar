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

package org.caisi.wl;

import javax.xml.bind.annotation.XmlAccessType;
import javax.xml.bind.annotation.XmlAccessorType;
import javax.xml.bind.annotation.XmlType;

/**
 * <p>
 * Java class for referralOutcomeBO complex type.
 * 
 * <p>
 * The following schema fragment specifies the expected content contained within
 * this class.
 * 
 * <pre>
 * &lt;complexType name="referralOutcomeBO">
 *   &lt;complexContent>
 *     &lt;restriction base="{http://www.w3.org/2001/XMLSchema}anyType">
 *       &lt;sequence>
 *         &lt;element name="accepted" type="{http://www.w3.org/2001/XMLSchema}boolean"/>
 *         &lt;element name="clientID" type="{http://www.w3.org/2001/XMLSchema}int"/>
 *         &lt;element name="rejectionReason" type="{http://www.w3.org/2001/XMLSchema}string" minOccurs="0"/>
 *         &lt;element name="vacancyID" type="{http://www.w3.org/2001/XMLSchema}int"/>
 *       &lt;/sequence>
 *     &lt;/restriction>
 *   &lt;/complexContent>
 * &lt;/complexType>
 * </pre>
 * 
 * 
 */
@XmlAccessorType(XmlAccessType.FIELD)
@XmlType(name = "referralOutcomeBO", propOrder = { "accepted", "clientID",
		"rejectionReason", "vacancyID" })
public class ReferralOutcomeBO {

	protected boolean accepted;
	protected int clientID;
	protected String rejectionReason;
	protected int vacancyID;

	/**
	 * Gets the value of the accepted property.
	 * 
	 */
	public boolean isAccepted() {
		return accepted;
	}

	/**
	 * Sets the value of the accepted property.
	 * 
	 */
	public void setAccepted(boolean value) {
		this.accepted = value;
	}

	/**
	 * Gets the value of the clientID property.
	 * 
	 */
	public int getClientID() {
		return clientID;
	}

	/**
	 * Sets the value of the clientID property.
	 * 
	 */
	public void setClientID(int value) {
		this.clientID = value;
	}

	/**
	 * Gets the value of the rejectionReason property.
	 * 
	 * @return possible object is {@link String }
	 * 
	 */
	public String getRejectionReason() {
		return rejectionReason;
	}

	/**
	 * Sets the value of the rejectionReason property.
	 * 
	 * @param value
	 *            allowed object is {@link String }
	 * 
	 */
	public void setRejectionReason(String value) {
		this.rejectionReason = value;
	}

	/**
	 * Gets the value of the vacancyID property.
	 * 
	 */
	public int getVacancyID() {
		return vacancyID;
	}

	/**
	 * Sets the value of the vacancyID property.
	 * 
	 */
	public void setVacancyID(int value) {
		this.vacancyID = value;
	}

}
