using System;
using Microsoft.Web.Administration;

namespace Carbon.Iis
{
    public sealed class HttpRedirectConfigurationSection : ConfigurationSection
    {
        public bool ChildOnly
        {
            get { return (bool)GetAttributeValue("childOnly"); }
            set { SetAttributeValue("childOnly", value); }
        }

        public string Destination
        {
            get { return GetAttributeValue("destination") as string; }
            set { SetAttributeValue("destination", value); }
        }

        public bool Enabled
        {
            get { return (bool) GetAttributeValue("enabled"); }
            set { SetAttributeValue("enabled", value); }
        }

        public bool ExactDestination
        {
            get { return (bool) GetAttributeValue("exactDestination"); }
            set { SetAttributeValue("exactDestination", value); }
        }

        public HttpResponseStatus HttpResponseStatus
        {
            get { return (HttpResponseStatus)(Int32)GetAttributeValue("httpResponseStatus"); }
            set { SetAttributeValue("httpResponseStatus", value); }
        }
    }
}
