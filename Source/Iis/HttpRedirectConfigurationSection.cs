// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//   
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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

