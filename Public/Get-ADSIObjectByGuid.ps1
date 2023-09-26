# Get-ADSIObjectByGuid.ps1

#*------v Function Get-ADSIObjectByGuid v------
Function Get-ADSIObjectByGuid {
    <#
    .SYNOPSIS
    Get-ADSIObjectByGuid.ps1 - Dependency-less function to retrieve an AD object - computer|group|contact - using it's AD object guid. Uses nothing more than windows native ADSI ActiveDirectory support - present in all Windows machines. 
    .NOTES
    Version     : 1.0.0
    Author      : Todd Kadrie
    Website     :	http://www.toddomation.com
    Twitter     :	@tostka / http://twitter.com/tostka
    CreatedDate : 2023-08-30
    FileName    : Get-ADSIComputerByGuid.ps1
    License     : (none asserted)
    Copyright   : (none asserted)
    Github      : https://github.com/tostka/verb-adms
    Tags        : Powershell,ADSI,ActiveDirectory,Computer
    AddedCredit : Ro Yo Mi
    AddedWebsite:	https://serverfault.com/users/171487/ro-yo-mi
    AddedTwitter:	URL
    AddedCredit : François-Xavier Cat
    AddedWebsite:	https://lazywinadmin.github.io/
    AddedTwitter:	@lazywinadmin / https://twitter.com/lazywinadmin
    REVISIONS
    10:12 AM 9/26/2023 working (add to vad); CBH working now (refactored 3x) ; pulled filter on mailcontact, uncommented the mailcontact block; updated CBH & examples
    * 11:26 AM 8/31/2023 init: validated all but -type:mailcontact works (documented msExchRecipientDisplayType is blank, on *all* xop MailContacts; can't filter that attrib at all, and get hits; default back to type:group wo the filtering for recipients)
    * 6/19/2023 Ro Yo Mi's posted code sample
    * 10/30/2013 lazywinadmin's original post
    .DESCRIPTION
    Get-ADSIObjectByGuid.ps1 - Dependency-less function to retrieve an AD object - computer|group|contact - using it's AD object guid. Uses nothing more than windows native ADSI ActiveDirectory support - present in all Windows machines. 
    I use this so that I can specify objects in code by storing their fairly obscure guid in scripts, and then resolve the guid back to the full object details, for connectivy.
    
        -type mailbox filters 'OR' on the following 'mailbox' recipient variants: 
        Usermailbox|Sharedmailbox|RoomMailbox|RemoteMailUser|EquipmentMailbox|RemoteUserMailbox|RemoteRoomMailbox|RemoteEquipmentMailbox|RemoteSharedMailbox
    
        (same token, if local Exchange Mgmt Shell support can store recipients using the underlying Exchange guid, and use (get-recipient xxx).primarysmtpaddress to retrive the matching object's email address for specifying Notification addreses
        But this works with or without Exch/EXO connectivity, and has no module dependancy, as long as you locally load the code from this function)

    Properties returned per object type:
        - computer : 
        distinguishedname,description,name,whencreated,dnshostname,displayname,objectclass,objectCategory

        - group|distributiongroup :
        distinguishedname,description,name,whencreated,mailnickname,msexchrecipientdisplaytype,
        msexchrequireauthtosendto,mail,msexchhidefromaddresslists,objectclass,objectCategory,proxyaddresses,
        grouptype,info,whencreated,cn,managedby,member,displayname 

        - contact
        distinguishedname,description,name,givenname,sn,memberof,targetaddress,whencreated,
        mailnickname,mail,objectclass,objectCategory,proxyaddresses,whencreated,cn,displayname

        - user|mailbox:
        distinguishedname,description,name,whencreated,mailnickname,msexchrecipientdisplaytype,
        msexchremoterecipienttype,mail,objectclass,objectCategory,proxyaddresses,department,
        msexchwhenmailboxcreated,title,targetaddress,givenname,memberof,streetaddress,samaccountname,
        userprincipalname,countrycode,showinaddressbook,physicaldeliveryofficename,employeetype,initials,
        lastlogon,useraccountcontrol,postalcode,displayname,msexchrecipientdisplaytype,employeetype,
        initials,lastlogon,useraccountcontrol,postalcode,displayname,msexchrecipientdisplaytype,name,
        telephonenumber,mailnickname,employeenumber

    .PARAMETER  GUID
    Guid for AD object to be returned[-GUID 'nenncnnb-ennn-nfnc-nnnn-nnnnnnnnanne'
    .PARAMETER LDAPserver
    Domain to be searched[-LDAPserver 'sub.domain.com']
    .PARAMETER GUID
    Guid for AD object to be returned (the AD guid, not any assoicated Exchange guid)[-GUID 'nenncnnb-ennn-nfnc-nnnn-nnnnnnnnanne']
    .PARAMETER Type
    Type: LDAP objectCategory (or keyword for Computer|group|contact|user|mailbox|distributiongroup) for the target object[-Type 'computer']
    .PARAMETER LDAPserver
    Domain to be searched[-LDAPserver 'sub.domain.com'
    .EXAMPLE
    PS> Get-ADSIObjectByGuid -guid 'nnnnnnnn-nnnn-nnnn-nnnn-nnnnnnnnnnnn' -Type computer -LDAPserver SUB.DOM.DOMAIN.COM -verbose  ; 

    distinguishedname : {CN=SERVER,OU=OU,OU=SITE,DC=SUB,DC=DOM,DC=DOMAIN,DC=com}
    description       : {DESCRIPTIONTEXT}
    name              : {SERVER}
    whencreated       : {7/1/2014 3:27:24 PM}
    dnshostname       : {SERVER.SUB.DOM.DOMAIN.COM}
    displayname       : {SERVER$}
    objectclass       : {top, person, organizationalPerson, user...}
    objectCategory    : {CN=Computer,CN=Schema,CN=Configuration,DC=DOM,DC=DOMAIN,DC=COM}
    
    Demo resolving a guid to the full computer object.
    .EXAMPLE
    PS> Get-ADSIObjectByGuid -GUID 'nenncnnb-ennn-nfnc-nnnn-nnnnnnnnanne' -Type 'user' -LDAPserver 'SUB.DOMAIN.COM' -verbose ;
    Query user object on guid
    PS> Get-ADSIObjectByGuid -guid nccenen-n-n-bfaa-cnadnea -Type mailbox -LDAPserver global.ad.toro.com
    Query a mail recipient
    .EXAMPLE
    PS> Get-ADSIObjectByGuid -guid nfbn-nden-nban-nbn-ncnedfn -Type computer -LDAPserver SUB.DOM.DOMAIN.COM -verbose  ; 
    Query computer on guid
    .EXAMPLE
    PS> Get-ADSIObjectByGuid -guid nffaencd-en-nan-anfc-nfnenan -Type contact -LDAPserver SUB.DOM.DOMAIN.COM
    Query contact on guid
    .LINK
    https://github.com/tostka/verb-ADMS
    .LINK
    https://serverfault.com/questions/310529/search-ad-by-guid
    .LINK
    https://lazywinadmin.com/2013/10/powershell-get-domaincomputer-adsi.html
    #>
    
    [CmdletBinding()]
    PARAM(
        [Parameter(Position=0,ValueFromPipeline=$true, Mandatory=$true, HelpMessage="Guid for AD object to be returned[-GUID 'nenncnnb-ennn-nfnc-nnnn-nnnnnnnnanne'[-GUID 'nenncnnb-ennn-nfnc-nnnn-nnnnnnnnanne']")]
            [system.guid]$guid,
        [Parameter(Position=1, Mandatory=$true, HelpMessage="Type: LDAP objectCategory (or keyword for Computer|group|contact|user|mailbox|distributiongroup) for the target object[-Type 'computer']")]
            [ValidateSet('Computer','group','contact','user','mailbox','distributiongroup','mailcontact')]            
            [String[]]$Type,
        [Parameter(Mandatory=$true, HelpMessage="Domain to be searched[-LDAPserver 'sub.domain.com'")]
            $LDAPserver
    ) ;  
    BEGIN{
        <#
         LDAP filter Syntax:
         <filter>=(<attribute><operator><value>)
         or
         (<operator><filter1><filter2>)
         Operators
         = 	Equal to
         ~= 	Approximately equal to
         <= 	Lexicographically less than or equal to
         >= 	Lexicographically greater than or equal to
         & 	AND
         | 	OR
         ! 	NOT
			        to NOT something, lead it with a !(NOT), and enclose the structure with paras:
		 	        (&(mail=*)(!(objectClass=contact))) == "objects with some mail value and NOT objectClass=contact"
         Wildcards: 
         Get all entries: (objectClass=*)
         Get entries containing "bob" somewhere in the common name: (cn=*bob*)
         Get entries with a common name greater than or equal to "bob": (cn>='bob')
         Get all users with an e-mail attribute: (&(objectClass=user)(email=*))
         Get all entries without an e-mail attribute: (!(email=*))
         Get all user entries with an e-mail attribute and a surname equal to "smith":
 	        (&(sn=smith)(objectClass=user)(email=*))
         Get all user entries with a common name that starts with "andy","steve", or "margaret":
         (&(objectClass=user) | (cn=andy*)(cn=steve)(cn=margaret))
         (|(sAMAccountName=TransFloBillingMbx)(sAMAccountName=SQLservernotif))
         AD SYNTAX NOTES ::
         -----------------------------------------------------------
         User Type	objectClass		
 				        objectCategory	sAMAccountType	
         -----------------------------------------------------------
         User		top; person; organizationalPerson; user	
 				        Person			805306368	
 							
         Contact		top; person; organizationalPerson; contact
 				        Person			<none>
 											
         inetOrgPerson top; person; organizationalPerson; user; inetOrgPerson
 				        Person			805306368
 
         Computer	top; person; organizationalPerson; user; computer;
 				        Computer		805306369

         DL			group
					        group			268435457

         Dynamic DL	msExchDynamicDistributionList
					        ms-Exch-Dynamic-Distribution-List <none>

         PF			publicFolder
					        ms-Exch-Public-Folder <none>
        #>
        <#
         Underlying AD object range of recipient-related values: 

        [Exchange RecipientTypes | GetPS.dev](https://getps.dev/blog/exchange-recipienttypes/)
        November 16, 2020 · 4 min read    
        ### msExchRecipientDisplayType

        |DisplayName|Name|Value|
        |---|---|---|
        |ACL able Mailbox User|ACLableMailboxUser|1073741824|
        |Security Distribution Group|SecurityDistributionGroup|1043741833|
        |Equipment Mailbox|EquipmentMailbox|8|
        |Conference Room Mailbox|ConferenceRoomMailbox|7|
        |Remote Mail User|RemoteMailUser|6|
        |Private Distribution List|PrivateDistributionList|5|
        |Organization|Organization|4|
        |Dynamic Distribution Group|DynamicDistributionGroup|3|
        |Public Folder|PublicFolder|2|
        |Distribution Group|DistrbutionGroup|1|
        |Mailbox User|MailboxUser|0|
        |Synced Universal Security Group as Universal Security Group|SyncedUSGasUSG|-1073739511|
        |ACL able Synced Universal Secuirty Group as Contact|ACLableSyncedUSGasContact|-1073739514|
        |ACL able Synced Remote Mail User|ACLableSyncedRemoteMailUser|-1073740282|
        |ACL able Synced Mailbox User|ACLableSyncedMailboxUser|-1073741818|
        |Synced Universal Security Group as Contact|SyncedUSGasContact|-2147481338|
        |Synced Universal Security Group as Universal Distribution Group|SyncedUSGasUDG|-2147481343|
        |Synced Equipment Mailbox|SyncedEquipmentMailbox|-2147481594|
        |Synced Conference Room Mailbox|SyncedConferenceRoomMailbox|-2147481850|
        |Synced Remote Mail User|SyncedRemoteMailUser|-2147482106|
        |Synced Dynamic Distribution Group|SyncedDynamicDistributionGroup|-2147482874|
        |Synced Public Folder|SyncedPublicFolder|-2147483130|
        |Synced Universal Distribution Group as Contact|SyncedUDGasContact|-2147483386|
        |Synced Universal Distribution Group as Universal Distribution Group|SyncedUDGasUDG|-2147483391|
        |Synced Mailbox User|SyncedMailboxUser|-2147483642|


        ### msExchRecipientTypeDetails
        |DisplayName|Name|Value|
        |---|---|---|
        |Team Mailbox|TeamMailbox|137438953472|
        |Remote Shared Mailbox|RemoteSharedMailbox|34359738368|
        |Remote Equipment Mailbox|RemoteEquipmentMailbox|17179869184|
        |Remote Equipment Mailbox (IncorrectValue)|RemoteEquipmentMailbox|17173869184|
        |Remote Room Mailbox|RemoteRoomMailbox|8589934592|
        |Remote User Mailboxï¿½ï¿½ï¿½ï¿½ï¿½|RemoteUserMailbox|2147483648|
        |Role Group|RoleGroup|1073741824|
        |Discovery Mailbox|DiscoveryMailbox|536870912|
        |Room List|RoomList|268435456|
        |Linked User|LinkedUser|33554432|
        |Mailbox Plan|MailboxPlan|16777216|
        |Arbitration Mailbox|ArbitrationMailbox|8388608|
        |Microsoft Exchange|MicrosoftExchange|4194304|
        |Disabled User|DisabledUser|2097152|
        |Non-Universal Group|NonUniversalGroup|1048576|
        |Universal Security Group|UniversalSecurityGroup|524288|
        |Universal Distribution Group|UniversalDistributionGroup|262144|
        |Contact|Contact|131072|
        |User|User|65536|
        |Cross-Forest Mail Contact|MailForestContact|32768|
        |System Mailbox|SystemMailbox|16384|
        |System Attendant Mailbox|SystemAttendantMailbox|8192|
        |Public Folder|Public Folder|4096|
        |Dynamic Distribution Group|DynamicDistributionGroup|2048|
        |Mail-Enabled Universal Security Group|MailUniversalSecurityGroup|1024|
        |Mail-Enabled Non-Universal Distribution Group|MailNonUniversalGroup|512|
        |Mail-Enabled Universal Distribution Group|MailUniversalDistributionGroup|256|
        |Mail User|MailUser|128|
        |Mail Contact|MailContact|64|
        |Equipment Mailbox|EquipmentMailbox|32|
        |Room Mailbox|RoomMailbox|16|
        |Legacy Mailbox|LegacyMailbox|8|
        |Shared Mailbox|SharedMailbox|4|
        |Linked Mailbox|LinkedMailbox|2|
        |User Mailbox|UserMailbox|1|

        ### msExchRecipientTypeDetails 
        |1|UserMailbox|
        |---|---|
        |2|LinkedMailbox|
        |4|SharedMailbox|
        |16|RoomMailbox|
        |32|EquipmentMailbox|
        |128|MailUser|
        |2147483648|RemoteUserMailbox|
        |8589934592|RemoteRoomMailbox|
        |17179869184|RemoteEquipmentMailbox|
        |34359738368|RemoteSharedMailbox|
        #>  
        switch ($type){
            'computer'{
                write-verbose "Type:computer specified" ; 
                # "(&(objectCategory=$($type))(DistinguishedName=$($DistinguishedName)))"
                $filterType = "(objectCategory=computer)" ; 
                $prps= 'distinguishedname','description','name','whencreated','dnshostname','displayname','objectclass','objectCategory' | select -unique ; ; 
            }
            'group'{
                write-verbose "Type:group specified" ; 
                $filterType = "(objectCategory=group)" ; 
                $prps= 'distinguishedname','description','name','whencreated','mailnickname','msexchrecipientdisplaytype',
                    'msexchrequireauthtosendto','mail','msexchhidefromaddresslists','objectclass','objectCategory','proxyaddresses',
                    'grouptype','info','whencreated','cn','managedby','member','displayname' | select -unique ; ;
            }
            'distributiongroup'{
                write-verbose "Type:distributiongroup specified (mail-enabled variant of group)" ; 
                <# DL MailUniversalDistributionGroup have msExchRecipientDisplayType : 1
                Security Distribution Group	SecurityDistributionGroup	1043741833
                #>
                #$filterType = "(objectCategory=group)" ; 
                $filterType = "(objectCategory=group)(|(msExchRecipientDisplayType=1)(msExchRecipientDisplayType=1043741833))"
                $prps= 'distinguishedname','description','name','whencreated','mailnickname','msexchrecipientdisplaytype',
                    'msexchrequireauthtosendto','mail','msexchhidefromaddresslists','objectclass','objectCategory','proxyaddresses',
                    'grouptype','info','whencreated','cn','managedby','member','displayname' | select -unique ; ;
            }
            'contact'{
                write-verbose "Type:contact specified" ;
                $filterType = "(objectCategory=contact)" 
                $prps= 'distinguishedname','description','name','givenname','sn','memberof','targetaddress','whencreated',
                    'mailnickname','mail','objectclass','objectCategory','proxyaddresses','whencreated','cn','displayname' | select -unique ; ;
                # missing: ,'msexchrecipientdisplaytype','msexchhidefromaddresslists''managedby',
            }
            # 2:14 PM 8/31/2023 disable: none of the 'MailContacts' have a functional msExchRecipientDisplayType set. Still unsure how to differentiate a Mailcontact from an AD.Contact, disable this block, until we have a better fiter
            # 9:19 AM 9/26/2023 actually, it still returns the proper target obj, wo the msExchRecipientDisplayType filter: objectCategory=contact & guid are sufficient to isolate the single object
            'mailcontact'{
                write-verbose "Type:contact specified (mailcontact-specific *not* supported at this point, no working msExchRecipientDisplayType value to target)" ;
                # MailContacts: msExchRecipientDisplayType            : 6
                #$filterType = "(objectCategory=contact)" 
                #$filterType = "(&(objectCategory=contact)(msExchRecipientDisplayType=6))" ; # Mailcontacts have blank msExchRecipientDisplayType, drop the filter
                $filterType = "(&(objectCategory=contact))" ; 
                # msExchRecipientDisplayType=6 consistently fails to match, go to populated
                $filterType = "(&(objectCategory=contact)(msExchRecipientDisplayType=*))" ; 
                # even * fails -> none of the 'MailContacts' have a functional msExchRecipientDisplayType set. Still unsure how to differentiate a Mailcontact from an AD.Contact, disable this block, until we have a better fiter
                $prps= 'distinguishedname','description','name','givenname','sn','memberof','targetaddress','whencreated',
                    'mailnickname','mail','objectclass','objectCategory','proxyaddresses','whencreated','cn','displayname' | select -unique ; ;
                # missing: ,'msexchrecipientdisplaytype','msexchhidefromaddresslists''managedby',
            }
            #
            'user'{
                write-verbose "Type:user specified" ; 
                <# - objectClass=user is slower/unindexed and returns computer objects
                   - objectCategory=Person is a faster indexed field than the unindexed objectClass, 
                	    but returns user, inetOrgPerson & contacts
                   - just want to find user and inetOrgPerson objects and not have contacts and/or computers returned?
                    use: (&(objectClass=user)(objectCategory=Person))
                #>
                # "(&(objectCategory=$($type))(DistinguishedName=$($DistinguishedName)))"
                $filterType = "&(objectClass=user)(objectCategory=Person)" ;
                $prps= 'distinguishedname','description','name','whencreated','mailnickname','msexchrecipientdisplaytype',
                    'msexchremoterecipienttype','mail','objectclass','objectCategory','proxyaddresses','department',
                    'msexchwhenmailboxcreated','title','targetaddress','givenname','memberof','streetaddress','samaccountname',
                    'userprincipalname','countrycode','showinaddressbook','physicaldeliveryofficename','employeetype','initials',
                    'lastlogon','useraccountcontrol','postalcode','displayname','msexchrecipientdisplaytype','employeetype',
                    'initials','lastlogon','useraccountcontrol','postalcode','displayname','msexchrecipientdisplaytype','name',
                    'telephonenumber','mailnickname','employeenumber' | select -unique ; 
            } ; 
            'mailbox'{
                write-verbose "Type:mailbox specified (mail-enabled variant of user)" ; 
                <# 
                AD - Spot *real* Exchange-managed objects (vs ADDistributionGroups, ADContacts, ADUsers w mail populated):
                Dl's have msExchRecipientDisplayType : 1
                OnPrem user mbxs: msExchRecipientDisplayType : 1073741824
                Remotemailboxes: msExchRecipientDisplayType : -2147483642
                   Note: they no longer have homemdb
                MailContacts: msExchRecipientDisplayType            : 6
                All Exchange-maintained objects have msExchRecipientDisplayType set. AD-objects 'faking' it won't. 
                (&(objectClass=user)(mail=*)(!(extensionAttribute2=*)))
                # or
                (|(msExchRecipientDisplayType=1073741824)(msExchRecipientDisplayType=-2147483642))

                # dump types: 
                get-recipient -filter {recipienttypedetails -eq 'UserMailbox'} -ResultSize 1 | select -expand samaccountname | %{get-aduser -id $_ -prop * | fl msExchRecipientDisplayType}

                Usermailbox  has msExchRecipientDisplayType  1073741824
                Sharedmailbox " 0
                RoomMailbox 7 
                RemoteMailUser 6
                EquipmentMailbox 8
                RemoteUserMailbox " -2147483642
                RemoteRoomMailbox has msExchRecipientDisplayType -2147481850
                RemoteEquipmentMailbox "  -2147481594
                RemoteSharedMailbox " -2147483642

                #>
                #$filterType = "&(objectClass=user)(objectCategory=Person)" ;
                # (&(objectClass=user)(mail=*))
                #$filterType = "&(objectClass=user)(mail=*)(|(msExchRecipientDisplayType=1073741824)(msExchRecipientDisplayType=-2147483642))"
                # add other variant msExchRecipientDisplayType's to the list
                $filterType = "&(objectClass=user)(mail=*)(|(msExchRecipientDisplayType=1073741824)(msExchRecipientDisplayType=0)(msExchRecipientDisplayType=6)(msExchRecipientDisplayType=7)(msExchRecipientDisplayType=8)(msExchRecipientDisplayType=-2147483642)(msExchRecipientDisplayType=-2147481850)(msExchRecipientDisplayType=-2147481594))"
                $prps= 'distinguishedname','description','name','whencreated','mailnickname','msexchrecipientdisplaytype',
                    'msexchremoterecipienttype','mail','objectclass','objectCategory','proxyaddresses','department',
                    'msexchwhenmailboxcreated','title','targetaddress','givenname','memberof','streetaddress','samaccountname',
                    'userprincipalname','countrycode','showinaddressbook','physicaldeliveryofficename','employeetype','initials',
                    'lastlogon','useraccountcontrol','postalcode','displayname','msexchrecipientdisplaytype','employeetype',
                    'initials','lastlogon','useraccountcontrol','postalcode','displayname','msexchrecipientdisplaytype','name',
                    'telephonenumber','mailnickname','employeenumber' | select -unique ; 
            }
        } ;
    } ;     
    PROCESS{
        <# Old LDAP/LDP/dsquery filtering notes:
        try to hybrid mbxs & dl's: ((class=user OR group) AND mail non-null) returned 11k items...
        set FILTER="(&(|(objectClass=user)(objectClass=group))(mail=*))"
        - mail-enabled users: (&(objectClass=user)(mail=*)) 
        -  this one returns all mail-enabled groups (dl's)
            set FILTER="(&(mail=*)(objectClass=group))"
        -  filter on displayname
            "(&(displayName=LASTNAME, FNAME))"
            (&(mail= Todd.Kadrie@Rbcdain.com))
            Primarysmtpaddress in the string
            (&(proxyAddresses=SMTP:*user@mydomain.com*))
        - LDAP - DL ManagedBy Search
            (managedBy=distinguishedNameOfPerson)
        - * If you wanted a list of Computers, showing their location, operatingSystem, operatingSystemVersion, and operatingSystemServicePack, use:
            dsquery * domainroot -filter "(&(objectCategory=Computer)(objectClass=User))" -attr distinguishedName location operatingSystem operatingSystemVersion operatingSystemServicePack -limit 0
        - set FIELDS="DN, displayName, info, mail, mailNickname, managedBy, name, proxyAddresses, sAMAccountName, sAMAccounttype, showInAddressbook, msExchRequireAuthToSendTo, description"
            "DN, displayName, sAMAccountName, proxyAddresses"
            "DN, employeeID, givenName, initials, sn, proxyAddresses, sAMAccountName"
            "DN, employeeID, givenName, initials, sn, proxyAddresses, sAMAccountName, employeeID, objectClass"
             for dl's or groups:
            "DN, displayName, info, mail, mailNickname, managedBy, name, proxyAddresses, sAMAccountName, sAMAccounttype, showInAddressbook, msExchRequireAuthToSendTo, description"
            "DN, employeeID, givenName, initials, sn, proxyAddresses, sAMAccountName, physicalDeliveryOfficeName, employeeID, telephoneNumber, title, homeMTA, msExchHomeServerName, description"

        -  query filter on 3 attributes:
             (&(&(objectClass=user)(objectClass=top))(objectClass=person))
             For 4 attributes, this would be:
             (&(&(&(objectClass=top)(objectClass=person))(objectClass=organizationalPerson))(objectClass=user))
        -  objectClass=user is slower/unindexed and returns computer objects
             objectCategory=Person is a faster indexed field than the unindexed objectClass, 
            		but returns user, inetOrgPerson & contacts
             just want to find user and inetOrgPerson objects and not have contacts and/or computers returned?
             use: (&(objectClass=user)(objectCategory=Person))
             or qry against the sAMAccounttype directly (same effect, also indexed, and very specific):
             		(sAMAccountType=805306368)

             only objects of inetOrgPerson class you can use the following filter.
            	(&(objectClass=inetOrgPerson)(objectCategory=Person))

             user objects without returning inetOrgPersons you need to specifically exclude inetOrgPerson
            	(&(sAMAccountType=805306368)(!(objectClass=inetOrgPerson)))

             in general searches that use the logical NOT operator (such as the one above) should be avoided 
            	unless there is no alternative.  This is because it can cause the query processor to return objects to 
            	which you do not have access or specific attributes that do not have a value.

             For more efficient searches start at the lowest point in the AD hierarchy that will give you the 
            	result you are looking for
        #>

        FOREACH ($item in $GUID){
            $GetItem  = "GUID=$($item)" ;
            write-verbose "LDAP://$($LDAPserver)/<$($GetItem)>..." ; 
            TRY{$DistinguishedName = $([ADSI]"LDAP://$($LDAPserver)/<$($GetItem)>").DistinguishedName} CATCH {$_ | fl * -Force; continue} ;
            if($DistinguishedName){
                TRY{
                    $Searcher = [ADSISearcher] ([ADSI] "LDAP://$($LDAPserver)") ;
                    #(&(objectCategory=$($type))(DistinguishedName=$($DistinguishedName)))
                    $fltr = "(&($($filterType))(DistinguishedName=$($DistinguishedName)))"
                    $Searcher.Filter = $fltr ; 
                    write-verbose "`$Searcher.Filter:`n$($Searcher.Filter)" ; 
                    FOREACH ($object in $($Searcher.FindAll())){
                        if($host.version.major -ge 3){$hsh = [ordered]@{'dummy' = $null} } 
                        else { $hsh = @{'dummy' = $null} ; } ; 
                        if($hsh.Contains('dummy')){$hsh.remove('dummy')} ; 
                        write-verbose "cycling & adding `$prps" ; 
                        $prps |foreach-object{
                            $hsh.add($_,$object.properties[$_]) 
                        } ; 
                        write-verbose "returning PSObject to pipeline" ; 
                        New-Object -TypeName PSObject -Property $hsh | write-output ;
                    } ; 
                } CATCH {$_ | fl * -Force; continue} 
            } else {throw "$($GetItem) failed to return a matching DistinguishedName" }; 
        } ; 
    } ; 
} ; 
#*------^ END Function Get-ADSIObjectByGuid ^------